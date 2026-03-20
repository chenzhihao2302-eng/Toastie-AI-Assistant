#!/usr/bin/env python3

# =========================
# 依赖导入
# =========================
from google import genai
from google.genai import types
from flask import Flask, jsonify, request
from flask_cors import CORS
from schema.health_schema import schema

import os
import json
import re
import secrets
import base64
from dotenv import load_dotenv

# 读取环境变量（例如 GEMINI_API_KEY）
load_dotenv()


# =========================
# 工具函数：会话 ID 生成
# =========================
def random_id_base64url(n_bytes=16):
    """
    生成一个随机 session id，用于区分不同用户会话。
    """
    return base64.urlsafe_b64encode(
        secrets.token_bytes(n_bytes)
    ).rstrip(b'=').decode()


# =========================
# 工具函数：组织模型输入内容
# =========================
def to_contents(history, user_text, session_id):
    """
    将当前会话历史和本次用户输入拼接成 Gemini 所需的 contents 格式。
    """
    return history.get(session_id, []) + [
        {
            "role": "user",
            "parts": [{"text": user_text}]
        }
    ]


# =========================
# 工具函数：解析模型输出
# =========================
def parse_model_response(res):
    """
    优先读取 Gemini 返回的 parsed 结果。
    如果没有 parsed，则尝试从文本中清理 markdown 标记后再转成 JSON。
    """
    out_obj = getattr(res, "parsed", None)

    if out_obj is None:
        raw = res.text or ""
        raw = re.sub(r"^```json|^```|```$", "", raw.strip(), flags=re.MULTILINE)
        out_obj = json.loads(raw) if raw else {"mode": "text", "text": ""}

    return out_obj


# =========================
# 工具函数：统一返回前端 payload
# =========================
def route_payload(data: dict, fallback_text=""):
    """
    根据模型返回内容，整理成前端统一可处理的格式。

    返回两种模式：
    1. 文本模式：{"mode": "text", "text": "..."}
    2. JSON 模式：{"mode": "json", "kind": "...", "data": {...}}
    """
    if data.get("mode") == "text":
        return {"mode": "text", "text": data.get("text", "")}

    for k in [
        "symptom_log",
        "meal_log",
        "medication_log",
        "stool_log",
        "period_log",
        "lab_report",
        "weight_log",
        "note_log"
    ]:
        if k in data:
            return {"mode": "json", "kind": k, "data": data[k]}

    return {"mode": "text", "text": fallback_text}


# =========================
# Flask 与 Gemini 初始化
# =========================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
app.config["SECRET_KEY"] = "secret!"

# 使用内存字典保存多轮对话历史
# key: session id
# value: 当前 session 的历史消息列表
history = {}

# 初始化 Gemini 客户端
client = genai.Client(api_key=GEMINI_API_KEY)


# =========================
# 主接口：AI 对话接口
# =========================
@app.route("/ai", methods=["POST"])
def text_to_ai():
    """
    统一处理文本输入和图片输入：
    - 如果没有 file，则按纯文本问答处理
    - 如果有 file，则按图片 + 文本混合输入处理
    """

    data = request.get_json()

    # 读取前端传来的 session id
    session_id = data.get("id")

    # 当前前端可能传 "null"，这里做兼容处理
    if not session_id or session_id == "null":
        session_id = random_id_base64url()

    # 如果是新会话，则初始化历史记录
    if session_id not in history:
        history.setdefault(session_id, [])

    print("session id:", session_id)

    # 获取用户输入的文本消息
    text = data.get("message", "")
    files = data.get("file")

    # =========================
    # 分支 1：纯文本输入
    # =========================
    if not files or files == []:
        print("text message:", text)

        res = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=to_contents(history, text, session_id),
            config={
                "response_mime_type": "application/json",
                "response_schema": schema,
            },
        )

        out_obj = parse_model_response(res)

        print("model response:", res.text)

        # 将本次用户消息和模型回复写入历史记录
        history[session_id].append({
            "role": "user",
            "parts": [{"text": text}]
        })
        history[session_id].append({
            "role": "model",
            "parts": [{"text": res.text or ""}]
        })

    # =========================
    # 分支 2：图片 + 文本输入
    # =========================
    else:
        print("image message:", text)

        # 这里的 file 默认按前端传来的数组处理
        # 每个元素应是图片字节内容或可转 bytes 的对象
        image_parts = [text]

        for file in files:
            image_parts.append(
                types.Part.from_bytes(
                    data=bytes(file),
                    mime_type="image/jpeg",
                )
            )

        # 先带上历史上下文，再补充图片输入
        contents = to_contents(history, text, session_id)
        contents.extend(image_parts)

        res = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=contents,
            config={
                "response_mime_type": "application/json",
                "response_schema": schema,
            },
        )

        out_obj = parse_model_response(res)

        print("model response:", res.text)

        # 图片分支这里仍然至少记录本次用户文本
        history[session_id].append({
            "role": "user",
            "parts": [{"text": text}]
        })
        history[session_id].append({
            "role": "model",
            "parts": [{"text": res.text or ""}]
        })

    # =========================
    # 整理返回结果
    # =========================
    payload = route_payload(out_obj, res.text or "")

    print("final payload:", {"id": session_id, **payload})

    return jsonify({"id": session_id, **payload}), 200


# =========================
# 启动服务
# =========================
if __name__ == "__main__":
    app.run(port=3902, debug=True)
