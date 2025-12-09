# Week 2: 編碼代理與 MCP 協議

## 概述

本週主要學習如何從零開始建構編碼代理和 Model Context Protocol (MCP) 的基礎概念。

## 檔案結構

```
week2/
├── coding_agent_from_scratch_lecture.py    # 編碼代理實現範例
├── simple_mcp.py                            # 簡單 MCP 伺服器範例
├── data/                                    # 課程資料
│   ├── lecture_9_29_25.txt                 # 09/29 講義 (從 PDF 轉換)
│   └── lecture_10_3_25.txt                 # 10/03 講義 (從 PDF 轉換)
└── README.md                                # 本檔案
```

## 講義內容

### lecture_9_29_25.txt
- **主題**: Building a Coding Agent From Scratch
- **內容**: 
  - 系統提示詞 (System Prompt) 的定義
  - 代理迴圈的步驟
  - 工具定義與執行

### lecture_10_3_25.txt
- **主題**: To MCP and Beyond
- **內容**:
  - Model Context Protocol 基礎
  - 為什麼需要 MCP (動態資料輸入)
  - MCP 與 RAG 的應用

## Python 練習檔案

### coding_agent_from_scratch_lecture.py
編碼代理的完整實現，包含：
- 工具註冊機制
- 系統提示詞管理
- LLM 呼叫迴圈
- 工具執行與回應處理

### simple_mcp.py
使用 FastMCP 框架的簡單 MCP 伺服器範例，展示如何：
- 定義 MCP 工具
- 檔案讀取操作
- 目錄列表操作
- 檔案編輯操作

## 資料準備說明

講義 PDF 檔案已轉換為 TXT 格式：
- 使用工具: `pdftotext`
- 轉換時間: 2025-12-09
- 位置: `data/` 資料夾

## 後續步驟

這些資料將用於進行課程的反向生成，類似於 week1 的教材處理邏輯。
