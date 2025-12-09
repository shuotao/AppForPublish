# Week 2 — 編碼代理與 MCP 協議實作

本週將透過實作練習，學習如何建構編碼代理系統以及 Model Context Protocol (MCP) 的整合。

***建議在開始之前先完整閱讀本文件。***

提示：預覽此 markdown 檔案
- Mac: 按 `Command (⌘) + Shift + V`
- Windows/Linux: 按 `Ctrl + Shift + V`

## 前置準備

### Ollama 安裝
確保已安裝並設定 Ollama。如果尚未安裝，請參考以下方法：

- macOS (Homebrew):
  ```bash
  brew install --cask ollama 
  ollama serve
  ```

- Linux:
  ```bash
  curl -fsSL https://ollama.com/install.sh | sh
  ```

驗證安裝：
```bash
ollama -v
```

下載本週需要的模型：
```bash
ollama run llama3.1:8b
```

### 環境設定
確保已設定 OpenAI API Key：
```bash
export OPENAI_API_KEY="your-api-key-here"
```

或建立 `.env` 檔案：
```
OPENAI_API_KEY=your-api-key-here
```

## 課程架構

本週包含兩個主要練習檔案：

### 1. 編碼代理實作 — `coding_agent_practice.py`
### 2. MCP 伺服器實作 — `mcp_server_practice.py`

完整說明請參閱各檔案內的 TODO 註解。

## 繳交內容

- 完成 `coding_agent_practice.py` 中所有標記為 `TODO` 的部分
- 完成 `mcp_server_practice.py` 中所有標記為 `TODO` 的部分
- 確保程式可以成功執行並通過測試
- ***再次確認所有 `TODO` 都已完成***

## 評分標準 (100 分)

- **編碼代理實作** (50 分)
- **MCP 伺服器實作** (50 分)
