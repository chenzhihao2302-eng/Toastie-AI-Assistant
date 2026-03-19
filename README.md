# Toastie - AI 健康助手

基于 Flutter + Flask 构建的多模态 AI 健康助手，支持文本、语音和图像输入，通过 Gemini API 实现智能对话与健康分析。

---

## 核心功能

* AI 对话（Gemini API）
* 语音输入与语音播报（STT + TTS）
* 图像输入辅助分析
* 多轮对话（基于 session id）
* 结构化 JSON 输出（便于前端解析）

---

## 技术栈

* 前端：Flutter / Dart
* 后端：Flask / Python
* AI：Gemini API

---

## 项目结构

```bash
Toastie-AI-Assistant/
├── backend/
│   └── adk.py
├── frontend/
│   ├── assistant_screen.dart
│   ├── assistant_chat_ui.dart
│   ├── assistant_listening_ui.dart
│   ├── assistant_response_ui.dart
│   ├── assistant_speaking_ui.dart
│   ├── assistant_thinking_ui.dart
│   └── send_to_server.dart
├── .gitignore
└── README.md


## 架构流程

Flutter → Flask API → Gemini → JSON → 前端渲染

---

## Demo

https://b23.tv/IGotWY6

---

## 说明

* API Key 通过环境变量配置（未上传）
* 本仓库为核心功能展示版本


## 关键文件说明

* `assistant_screen.dart`：主控制逻辑（状态切换 + 请求调度）

* `send_to_server.dart`：封装前后端通信（HTTP 请求）

* `assistant_chat_ui.dart`：聊天界面展示

* `assistant_listening_ui.dart`：语音监听状态 UI

* `assistant_response_ui.dart`：AI 回复展示

* `assistant_speaking_ui.dart`：语音播放状态

* `assistant_thinking_ui.dart`：AI 处理中状态

* `backend/adk.py`：Flask 后端接口（调用 Gemini API + 返回 JSON）
