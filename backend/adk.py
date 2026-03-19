#!/usr/bin/env python3
from google import genai
from google.genai import types
from flask import Flask, jsonify, request, abort
from flask_cors import CORS
import secrets
import base64
from schema.health_schema import schema 
import json, re

# from flask_socketio import SocketIO, emit, join_room, leave_room
import os
from dotenv import load_dotenv
load_dotenv()

def random_id_base64url(n_bytes=16):
    return base64.urlsafe_b64encode(secrets.token_bytes(n_bytes)).rstrip(b'=').decode()

def to_contents(history, user_text,id):
    
     return history.get(id, [])+ [{"role": "user", "parts": [{"text": user_text}]}]


def route_payload(data: dict):
        if data.get("mode") == "text":
            return {"mode": "text", "text": data.get("text", "")}
        for k in ["symptom_log","meal_log","medication_log","stool_log",
                    "period_log","lab_report","weight_log","note_log"]:
            if k in data:
                return {"mode": "json", "kind": k, "data": data[k]}
        return {"mode": "text", "text": data.get("text", "")}



GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
app.config['SECRET_KEY'] = 'secret!'
# chat_user={}
history={}
client = genai.Client(api_key=GEMINI_API_KEY)


@app.route('/ai', methods=["POST"])
def text_to_ai ():
    id = request.json.get("id")
    if id =="null":
        id = random_id_base64url()
    if id not in history.keys():
        # chat_user[id] = client.chats.create(model="gemini-2.5-flash")
        history.setdefault(id, [])

    # chat = chat_user[id]
    print(id)
    if  not request.json.get("file") or request.json.get("file")==[]:
        text = request.json.get("message")
        print(text)
        
        res = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=to_contents(history, text,id),
            config={
                'response_mime_type': 'application/json',
                'response_schema': schema,
            },
        )
        
        out_obj = getattr(res, "parsed", None)
        if out_obj is None:
            raw = res.text or ""
            raw = re.sub(r"^```json|^```|```$", "", raw.strip(), flags=re.MULTILINE)
            out_obj = json.loads(raw) if raw else {"mode": "text", "text": ""}

        print(res.text)
        history[id].append({"role": "user", "parts": [{"text": text}]})
        history[id].append({"role": "model", "parts": [{"text": res.text or ""}]})
  
       
    else:
        # print(request.json)
        files = request.json.get("file")
        if not files and "file" in request.files:
            files = [request.json.get["file"]]
        # print(files)
        # image_bytes=request.json.get("file")
        text = request.json.get("message")
        image=[text]
        for file in files:
            # print(file)
            # data = file.read()  # bytes
            image.append(
            types.Part.from_bytes(
                data=bytes(file),
                mime_type= "image/jpeg",
            )
        ) 
        # print(image)
        content=to_contents(history, text,id)
        content.extend(image)
        res = client.models.generate_content(
            model="gemini-2.5-flash",
             contents=content,
             config={
                'response_mime_type': 'application/json',
                'response_schema': schema,
            },
        )
        out_obj = getattr(res, "parsed", None)
        # print(out_obj)
        if out_obj is None:
            raw = res.text or ""
            raw = re.sub(r"^```json|^```|```$", "", raw.strip(), flags=re.MULTILINE)
            out_obj = json.loads(raw) if raw else {"mode": "text", "text": ""}

      
        print(res.text)
        history[id].append({"role": "user", "parts": [{"text": text}]})
    # return jsonify("hello"),200
    
    history[id].append({"role": "model", "parts": [{"text": res.text or ""}]})
    
    def route_payload(data: dict):
        if data.get("mode") == "text":
            return {"mode": "text", "text": data.get("text", "")}
        for k in ["symptom_log","meal_log","medication_log","stool_log",
                    "period_log","lab_report","weight_log","note_log"]:
            if k in data:
                return {"mode": "json", "kind": k, "data": data[k]}
        return {"mode": "text", "text": res.text or ""}
    payload = route_payload(out_obj)
    
    print(jsonify({"id": id, **payload}))
    return jsonify({"id": id, **payload}), 200
    # return jsonify("hello"),200

  
# @app.route('/del/<string:id>', methods=['DELETE'])
# def delete(id):
#     if id in chat_user:
#         chat_user.pop(id)
#     # print(chat_user)
#     return jsonify(),204



"""

https://ai.google.dev/gemini-api/docs/image-understanding?hl=zh-cn
"""
if __name__ == '__main__':
    app.run(port=3902, debug=True)
