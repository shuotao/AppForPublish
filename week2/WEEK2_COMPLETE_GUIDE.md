# 📚 史丹佛 Week 2：編碼代理與 MCP 協議完整學習指南

**課程代碼：** CS146S | **授課教授：** Mihail Eric  
**大學：** Stanford University, Fall 2025

---

# 🎯 這份指南的目標

這份指南專為**想深入理解 AI 編碼助手原理**的學習者設計。我們會：

1. ✅ 解釋編碼代理的每個組成部分（用日常語言）
2. ✅ 提供完整的程式碼範例（可直接複製執行）
3. ✅ 展示每個步驟的預期結果和輸出
4. ✅ 詳細解析 Model Context Protocol (MCP)
5. ✅ 讓您從零開始，完成兩個完整的實作專案

---

# 📖 目錄

- [第一章：編碼代理基礎](#第一章編碼代理基礎)
- [第二章：環境設定](#第二章環境設定)
- [第三章：建構編碼代理 - 詳細實作](#第三章建構編碼代理)
- [第四章：Model Context Protocol (MCP)](#第四章model-context-protocol)
- [第五章：實作練習指南](#第五章實作練習指南)
- [第六章：除錯與最佳實踐](#第六章除錯與最佳實踐)
- [第七章：進階主題](#第七章進階主題)

---

# 📖 第一章：編碼代理基礎

## 1.1 什麼是編碼代理？

**編碼代理 (Coding Agent)** = 能夠**使用工具**來完成編碼任務的 AI 系統

想像您有一個 AI 助手：
- 他可以**讀取檔案**了解程式碼
- 他可以**修改檔案**修復 bug
- 他可以**列出目錄**探索專案
- 他可以**自己決定**何時使用工具

**範例情境：**
```
您說：「幫我建立一個 hello.py 檔案，印出 Hello World」

代理的執行過程：
1. 🤔 分析任務：需要建立新檔案
2. 🔧 選擇工具：edit_file_tool
3. 📝 執行操作：
   tool: edit_file({"path": "hello.py", "old_str": "", "new_str": "print('Hello World')"})
4. ✅ 回報結果：「已成功建立 hello.py」
```

## 1.2 編碼代理 vs 一般 LLM

| 特性 | 一般 LLM | 編碼代理 |
|------|---------|---------|
| 能力 | 只能**回答問題** | 可以**執行動作** |
| 工具 | 無法使用外部工具 | 可以讀寫檔案、執行命令 |
| 流程 | 單次對話 | 多步驟推理和執行 |
| 比喻 | 顧問 | 實際動手的工程師 |

## 1.3 核心元件

```
編碼代理的六大組件：

1. 系統提示詞 → 定義代理行為和規則
2. 對話管理   → 維護對話歷史記錄
3. LLM 推理   → 決定何時使用什麼工具
4. 工具註冊表 → 儲存所有可用工具
5. 工具執行   → 實際執行檔案操作
6. 結果回饋   → 將結果回傳給 LLM 繼續
```

---

# 🛠️ 第二章：環境設定

## 2.1 所需工具清單

```bash
# 1. Python 3.8 或更新版本
python3 --version

# 2. pip 套件管理器
pip3 --version
```

## 2.2 安裝 Python 套件

```bash
# 安裝 OpenAI SDK（用於呼叫 GPT 模型）
pip3 install openai

# 安裝環境變數管理工具
pip3 install python-dotenv

# 安裝 FastMCP 框架（用於建立 MCP 伺服器）
pip3 install fastmcp

# （選用）安裝 Ollama（用於本地模型）
pip3 install ollama
```

## 2.3 設定 API Key

### 方法 1：環境變數

```bash
# 在終端機中設定（暫時性）
export OPENAI_API_KEY="your-actual-api-key-here"

# 驗證是否設定成功
echo $OPENAI_API_KEY
```

### 方法 2：建立 .env 檔案

在 `week2/` 資料夾中建立 `.env` 檔案：

```bash
cd /path/to/week2
cat > .env << 'EOF'
OPENAI_API_KEY=your-actual-api-key-here
EOF
```

## 2.4 測試環境

建立測試檔案 `test_setup.py`：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

# 檢查 API Key
api_key = os.environ.get("OPENAI_API_KEY")
if not api_key:
    print("❌ OPENAI_API_KEY 未設定")
else:
    print(f"✅ API Key 已設定（前 10 個字元）: {api_key[:10]}...")
    
# 測試 API 連接
try:
    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": "Say hello"}],
        max_tokens=10
    )
    print("✅ OpenAI API 連接成功")
    print(f"回應: {response.choices[0].message.content}")
except Exception as e:
    print(f"❌ API 連接失敗: {e}")
```

執行測試：
```bash
python3 test_setup.py
```

---

# 📚 第三章：建構編碼代理

## 3.1 系統提示詞設計

### 什麼是系統提示詞？

**系統提示詞** = 編碼代理的「說明書」

它告訴 LLM：
- 你的角色是什麼
- 你有哪些工具可用
- 如何使用這些工具
- 工具呼叫的格式規範

### 好的系統提示詞範例

```python
SYSTEM_PROMPT = """
你是一個編碼助手，目標是協助解決編碼任務。
你可以使用以下工具：

{tool_list_repr}

**工具呼叫格式：**
當需要使用工具時，請以以下格式回覆（只回覆這一行）：
tool: TOOL_NAME({{"param1": "value1", "param2": "value2"}})

**重要規則：**
1. 使用緊湊的單行 JSON，必須使用雙引號
2. 收到 tool_result(...) 後，繼續任務
3. 如果不需要工具，正常回應即可
4. 一次只呼叫一個工具

**範例：**
讀取檔案：tool: read_file({{"filename": "test.py"}})
列出目錄：tool: list_files({{"path": "."}})
建立檔案：tool: edit_file({{"path": "new.py", "old_str": "", "new_str": "print('hello')"}})
"""
```

### 系統提示詞的關鍵要素

```
✅ 1. 角色定義
   「你是一個編碼助手...」
   
✅ 2. 工具清單
   列出所有可用工具及其說明
   
✅ 3. 格式規範
   精確說明工具呼叫的格式
   
✅ 4. 執行規則
   說明收到結果後如何繼續
   
✅ 5. 範例展示
   提供具體的呼叫範例
```

## 3.2 工具實作詳解

### 工具 1：讀取檔案 (read_file_tool)

**用途：** 讀取指定檔案的完整內容

**完整實作：**

```python
from pathlib import Path
from typing import Any, Dict

def resolve_abs_path(path_str: str) -> Path:
    """
    將相對路徑或 ~ 路徑轉換為絕對路徑
    
    範例：
    "test.py" → "/Users/your_name/project/test.py"
    "~/Desktop/file.txt" → "/Users/your_name/Desktop/file.txt"
    """
    path = Path(path_str).expanduser()  # 展開 ~ 符號
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()  # 轉為絕對路徑
    return path

def read_file_tool(filename: str) -> Dict[str, Any]:
    """
    讀取檔案的完整內容
    
    參數：
        filename (str): 要讀取的檔案路徑
        
    回傳：
        dict: {
            "file_path": 完整路徑,
            "content": 檔案內容
        }
    
    範例：
        >>> read_file_tool("test.py")
        {
            "file_path": "/Users/you/project/test.py",
            "content": "print('hello world')"
        }
    """
    # 步驟 1：取得絕對路徑
    full_path = resolve_abs_path(filename)
    print(f"[DEBUG] 讀取檔案: {full_path}")
    
    # 步驟 2：讀取檔案內容
    try:
        with open(str(full_path), "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        return {
            "error": "file_not_found",
            "message": f"檔案不存在: {filename}"
        }
    except PermissionError:
        return {
            "error": "permission_denied",
            "message": f"沒有權限讀取: {filename}"
        }
    
    # 步驟 3：回傳結果
    return {
        "file_path": str(full_path),
        "content": content
    }
```

**使用流程：**
```
LLM 呼叫: tool: read_file({"filename": "test.py"})
      ↓
系統執行: read_file_tool("test.py")
      ↓
讀取檔案: /Users/you/project/test.py
      ↓
回傳結果: {"file_path": "...", "content": "print('hello')"}
      ↓
LLM 收到: tool_result({"file_path": "...", "content": "print('hello')"})
```

### 工具 2：列出目錄 (list_files_tool)

**用途：** 列出指定目錄中的所有檔案和子目錄

**完整實作：**

```python
def list_files_tool(path: str) -> Dict[str, Any]:
    """
    列出目錄中的所有檔案和資料夾
    
    參數：
        path (str): 要列出的目錄路徑
        
    回傳：
        dict: {
            "path": 完整路徑,
            "files": [
                {"filename": "file1.py", "type": "file"},
                {"filename": "folder1", "type": "dir"},
                ...
            ]
        }
    """
    # 步驟 1：取得絕對路徑
    full_path = resolve_abs_path(path)
    print(f"[DEBUG] 列出目錄: {full_path}")
    
    # 步驟 2：檢查路徑是否存在
    if not full_path.exists():
        return {
            "error": "path_not_found",
            "message": f"路徑不存在: {path}"
        }
    
    if not full_path.is_dir():
        return {
            "error": "not_a_directory",
            "message": f"路徑不是目錄: {path}"
        }
    
    # 步驟 3：遍歷目錄
    all_files = []
    try:
        for item in full_path.iterdir():
            all_files.append({
                "filename": item.name,
                "type": "file" if item.is_file() else "dir"
            })
    except PermissionError:
        return {
            "error": "permission_denied",
            "message": f"沒有權限讀取目錄: {path}"
        }
    
    # 步驟 4：排序（資料夾在前，檔案在後）
    all_files.sort(key=lambda x: (x["type"] == "file", x["filename"]))
    
    # 步驟 5：回傳結果
    return {
        "path": str(full_path),
        "files": all_files
    }
```

**範例輸出：**
```python
# LLM 呼叫
tool: list_files({"path": "."})

# 系統回傳
{
    "path": "/Users/you/project",
    "files": [
        {"filename": "src", "type": "dir"},
        {"filename": "tests", "type": "dir"},
        {"filename": "README.md", "type": "file"},
        {"filename": "setup.py", "type": "file"}
    ]
}
```

### 工具 3：編輯檔案 (edit_file_tool)

**用途：** 建立新檔案或修改現有檔案

**完整實作：**

```python
def edit_file_tool(path: str, old_str: str, new_str: str) -> Dict[str, Any]:
    """
    建立或編輯檔案
    
    參數：
        path (str): 檔案路徑
        old_str (str): 要替換的字串（空字串表示建立新檔案）
        new_str (str): 替換後的字串（或新檔案的內容）
        
    回傳：
        dict: {
            "path": 完整路徑,
            "action": "created_file" | "edited" | "old_str not found"
        }
    
    使用情境：
    1. 建立新檔案: old_str = ""
    2. 修改現有檔案: old_str = 要替換的內容
    """
    # 步驟 1：取得絕對路徑
    full_path = resolve_abs_path(path)
    print(f"[DEBUG] 編輯檔案: {full_path}")
    
    # 情況 1：建立新檔案（old_str 為空）
    if old_str == "":
        print(f"[DEBUG] 建立新檔案")
        try:
            # 確保父目錄存在
            full_path.parent.mkdir(parents=True, exist_ok=True)
            # 寫入內容
            full_path.write_text(new_str, encoding="utf-8")
            return {
                "path": str(full_path),
                "action": "created_file"
            }
        except Exception as e:
            return {
                "error": "create_failed",
                "message": f"建立檔案失敗: {e}"
            }
    
    # 情況 2：修改現有檔案
    try:
        # 讀取原始內容
        original = full_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {
            "error": "file_not_found",
            "message": f"檔案不存在，無法編輯: {path}"
        }
    except PermissionError:
        return {
            "error": "permission_denied",
            "message": f"沒有權限讀取檔案: {path}"
        }
    
    # 檢查是否找到要替換的字串
    if original.find(old_str) == -1:
        print(f"[DEBUG] 找不到要替換的字串")
        return {
            "path": str(full_path),
            "action": "old_str not found",
            "message": f"找不到指定的字串: {old_str[:50]}..."
        }
    
    # 執行替換（只替換第一次出現）
    edited = original.replace(old_str, new_str, 1)
    
    try:
        full_path.write_text(edited, encoding="utf-8")
        print(f"[DEBUG] 編輯成功")
        return {
            "path": str(full_path),
            "action": "edited"
        }
    except Exception as e:
        return {
            "error": "write_failed",
            "message": f"寫入檔案失敗: {e}"
        }
```

**使用範例：**

```python
# 範例 1：建立新檔案
tool: edit_file({
    "path": "hello.py",
    "old_str": "",
    "new_str": "print('Hello World')"
})
# 回傳: {"path": "...", "action": "created_file"}

# 範例 2：修改現有檔案
tool: edit_file({
    "path": "hello.py",
    "old_str": "print('Hello World')",
    "new_str": "print('Hello Python')"
})
# 回傳: {"path": "...", "action": "edited"}
```

## 3.3 工具註冊表

**用途：** 管理所有可用的工具

```python
import inspect

# 工具註冊字典
TOOL_REGISTRY = {
    "read_file": read_file_tool,
    "list_files": list_files_tool,
    "edit_file": edit_file_tool
}

def get_tool_str_representation(tool_name: str) -> str:
    """
    產生工具的字串描述（用於系統提示詞）
    """
    tool = TOOL_REGISTRY[tool_name]
    return f"""
    名稱: {tool_name}
    說明: {tool.__doc__}
    參數: {inspect.signature(tool)}
    """

def get_full_system_prompt() -> str:
    """
    產生完整的系統提示詞（包含所有工具描述）
    """
    tool_descriptions = ""
    for tool_name in TOOL_REGISTRY:
        tool_descriptions += "工具\n" + "="*50
        tool_descriptions += get_tool_str_representation(tool_name)
        tool_descriptions += "\n" + "="*50 + "\n"
    
    return SYSTEM_PROMPT.format(tool_list_repr=tool_descriptions)
```

## 3.4 工具呼叫解析

**用途：** 從 LLM 回應中提取工具呼叫

**LLM 回應格式：**
```
tool: read_file({"filename": "test.py"})
```

**解析實作：**

```python
import json
import re
from typing import List, Tuple, Dict, Any

def extract_tool_invocations(text: str) -> List[Tuple[str, Dict[str, Any]]]:
    """
    從 LLM 回應中提取工具呼叫
    
    參數：
        text: LLM 的完整回應文字
        
    回傳：
        List[Tuple[工具名稱, 參數字典]]
        
    範例：
        輸入: "tool: read_file({\"filename\": \"test.py\"})"
        輸出: [("read_file", {"filename": "test.py"})]
    """
    invocations = []
    
    # 按行處理
    for raw_line in text.splitlines():
        line = raw_line.strip()
        
        # 步驟 1：檢查是否為工具呼叫行
        if not line.startswith("tool:"):
            continue
        
        try:
            # 步驟 2：移除 "tool:" 前綴
            after = line[len("tool:"):].strip()
            
            # 步驟 3：分離工具名稱和參數
            # 格式：TOOL_NAME({"param": "value"})
            name, rest = after.split("(", 1)
            name = name.strip()
            
            # 步驟 4：檢查括號是否閉合
            if not rest.endswith(")"):
                print(f"[警告] 括號未閉合: {line}")
                continue
            
            # 步驟 5：提取 JSON 參數
            json_str = rest[:-1].strip()  # 移除最後的 )
            
            # 步驟 6：解析 JSON
            args = json.loads(json_str)
            
            # 步驟 7：加入結果列表
            invocations.append((name, args))
            print(f"[DEBUG] 解析工具呼叫: {name} with {args}")
            
        except json.JSONDecodeError as e:
            print(f"[錯誤] JSON 解析失敗: {line}")
            print(f"       原因: {e}")
            continue
        except ValueError as e:
            print(f"[錯誤] 格式解析失敗: {line}")
            print(f"       原因: {e}")
            continue
        except Exception as e:
            print(f"[錯誤] 未知錯誤: {line}")
            print(f"       原因: {e}")
            continue
    
    return invocations
```

**測試範例：**

```python
# 測試 1：正常格式
text1 = 'tool: read_file({"filename": "test.py"})'
result1 = extract_tool_invocations(text1)
print(result1)
# 輸出: [('read_file', {'filename': 'test.py'})]

# 測試 2：多個工具呼叫
text2 = '''
先列出目錄看看...
tool: list_files({"path": "."})
然後讀取檔案...
tool: read_file({"filename": "README.md"})
'''
result2 = extract_tool_invocations(text2)
print(result2)
# 輸出: [('list_files', {'path': '.'}), ('read_file', {'filename': 'README.md'})]

# 測試 3：錯誤格式
text3 = "tool: read_file({'filename': 'test.py'})"  # 單引號（錯誤）
result3 = extract_tool_invocations(text3)
print(result3)
# 輸出: [] （解析失敗）
```

## 3.5 對話迴圈（Agent Loop）

**用途：** 主要的代理執行迴圈

**完整實作：**

```python
from openai import OpenAI

def execute_llm_call(conversation: List[Dict[str, str]], model: str = "gpt-4o-mini") -> str:
    """
    呼叫 OpenAI API
    
    參數：
        conversation: 對話歷史
        model: 模型名稱
        
    回傳：
        LLM 的回應文字
    """
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    
    response = client.chat.completions.create(
        model=model,
        messages=conversation,
        max_completion_tokens=2000,
        temperature=0.3
    )
    
    return response.choices[0].message.content


def run_coding_agent_loop():
    """
    執行編碼代理的主迴圈
    
    流程：
    1. 接收使用者輸入
    2. 呼叫 LLM
    3. 檢查是否有工具呼叫
    4. 執行工具
    5. 將結果回傳給 LLM
    6. 重複 2-5 直到 LLM 給出最終回應
    7. 重複 1-6
    """
    print("="*60)
    print("編碼代理已啟動！")
    print("輸入您的指令，或按 Ctrl+C 結束。")
    print("="*60)
    print()
    
    # 初始化對話歷史
    conversation = [{
        "role": "system",
        "content": get_full_system_prompt()
    }]
    
    # 主迴圈
    while True:
        try:
            # ========== 步驟 1：接收使用者輸入 ==========
            user_input = input(f"{YOU_COLOR}You:{RESET_COLOR} ")
            
            if not user_input.strip():
                continue
                
            conversation.append({
                "role": "user",
                "content": user_input.strip()
            })
            
            # ========== 步驟 2-5：工具執行迴圈 ==========
            while True:
                # 步驟 2：呼叫 LLM
                print(f"\n{ASSISTANT_COLOR}[思考中...]{RESET_COLOR}")
                assistant_response = execute_llm_call(conversation)
                
                # 步驟 3：檢查是否有工具呼叫
                tool_invocations = extract_tool_invocations(assistant_response)
                
                # 步驟 3a：沒有工具呼叫，顯示最終回應
                if not tool_invocations:
                    print(f"{ASSISTANT_COLOR}Assistant:{RESET_COLOR} {assistant_response}")
                    conversation.append({
                        "role": "assistant",
                        "content": assistant_response
                    })
                    break
                
                # 步驟 4：執行每個工具
                for tool_name, args in tool_invocations:
                    print(f"\n{ASSISTANT_COLOR}[執行工具: {tool_name}]{RESET_COLOR}")
                    print(f"參數: {args}")
                    
                    # 檢查工具是否存在
                    if tool_name not in TOOL_REGISTRY:
                        error_msg = f"錯誤：未知的工具 '{tool_name}'"
                        print(f"❌ {error_msg}")
                        conversation.append({
                            "role": "user",
                            "content": f"tool_result({{\"error\": \"{error_msg}\"}})"
                        })
                        continue
                    
                    # 執行工具
                    tool = TOOL_REGISTRY[tool_name]
                    
                    try:
                        # 根據不同工具傳遞正確的參數
                        if tool_name == "read_file":
                            result = tool(args.get("filename", ""))
                        elif tool_name == "list_files":
                            result = tool(args.get("path", "."))
                        elif tool_name == "edit_file":
                            result = tool(
                                args.get("path", ""),
                                args.get("old_str", ""),
                                args.get("new_str", "")
                            )
                        else:
                            result = {"error": f"未實作的工具: {tool_name}"}
                        
                        print(f"✅ 執行結果: {result}")
                        
                        # 步驟 5：將工具結果加入對話
                        conversation.append({
                            "role": "user",
                            "content": f"tool_result({json.dumps(result, ensure_ascii=False)})"
                        })
                        
                    except Exception as e:
                        error_result = {"error": f"工具執行錯誤: {str(e)}"}
                        print(f"❌ {error_result}")
                        conversation.append({
                            "role": "user",
                            "content": f"tool_result({json.dumps(error_result)})"
                        })
            
            print()  # 空行分隔
            
        except (KeyboardInterrupt, EOFError):
            print("\n\n再見！")
            break
        except Exception as e:
            print(f"\n❌ 發生錯誤: {e}")
            import traceback
            traceback.print_exc()


# 程式入口點
if __name__ == "__main__":
    run_coding_agent_loop()
```

### 執行流程範例

**完整對話範例：**

```
============================================================
編碼代理已啟動！
輸入您的指令，或按 Ctrl+C 結束。
============================================================

You: 建立一個 greet.py，包含一個問候函式

[思考中...]

[執行工具: edit_file]
參數: {'path': 'greet.py', 'old_str': '', 'new_str': "def greet(name):\n    return f'Hello, {name}!'"}
✅ 執行結果: {'path': '/Users/you/project/greet.py', 'action': 'created_file'}

[思考中...]
Assistant: 已成功建立 greet.py 檔案，包含 greet 函式。

You: 列出當前目錄的檔案

[思考中...]

[執行工具: list_files]
參數: {'path': '.'}
✅ 執行結果: {'path': '/Users/you/project', 'files': [{'filename': 'greet.py', 'type': 'file'}]}

[思考中...]
Assistant: 當前目錄包含一個檔案：greet.py

You: 讀取 greet.py 的內容

[思考中...]

[執行工具: read_file]
參數: {'filename': 'greet.py'}
✅ 執行結果: {'file_path': '/Users/you/project/greet.py', 'content': "def greet(name):\n    return f'Hello, {name}!'"}

[思考中...]
Assistant: greet.py 的內容如下：
def greet(name):
    return f'Hello, {name}!'
```

---

# 📚 第四章：Model Context Protocol (MCP)

## 4.1 為什麼需要 MCP？

### 問題：M×N 連接器困境

**情境：**
假設我們有：
- 5 種 AI 應用程式（Claude Desktop, ChatGPT, Copilot, Cursor, Cline）
- 6 種資料來源（Google Drive, GitHub, Notion, Slack, Calendar, Database）

如果每個應用程式都要各自實作對每個資料來源的支援：

```
所需連接器數量 = 5 × 6 = 30 個
```

每次新增一個應用程式或資料來源，都要重新實作所有連接器！

### 解決方案：統一協議

使用 MCP：
```
所需連接器數量 = 5 + 6 = 11 個
  (5 個 MCP 客戶端 + 6 個 MCP 伺服器)
```

**圖解：**

```
傳統方式（M×N）：
AI App 1 -----> Data Source 1
    \----> Data Source 2
    \----> Data Source 3

AI App 2 -----> Data Source 1
    \----> Data Source 2
    \----> Data Source 3

... 共 M×N 個連接器


MCP 方式（M+N）：
AI App 1 ----\
AI App 2 -----}--> MCP 協議 -->{---> MCP Server 1 (Data Source 1)
AI App 3 ----/                 \---> MCP Server 2 (Data Source 2)
                                \---> MCP Server 3 (Data Source 3)
```

## 4.2 MCP 核心概念

### MCP 架構三元素

```
1. MCP 客戶端 (Client)
   - AI 應用程式（如 Claude Desktop）
   - 發起工具呼叫請求
   
2. MCP 伺服器 (Server)
   - 提供工具實作
   - 回應客戶端請求
   
3. MCP 協議
   - 標準化的通訊格式
   - JSON-RPC 2.0 為基礎
```

### MCP 通訊流程

```
步驟 1：客戶端請求工具列表
Client --> Server: {"method": "tools/list"}
Client <-- Server: [{"name": "read_file", "description": "..."}, ...]

步驟 2：客戶端呼叫工具
Client --> Server: {
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": {"filename": "test.py"}
  }
}

步驟 3：伺服器回傳結果
Client <-- Server: {
  "result": {
    "content": "print('hello')"
  }
}
```

## 4.3 使用 FastMCP 建立伺服器

### 什麼是 FastMCP？

FastMCP = 簡化 MCP 伺服器開發的 Python 框架

**特點：**
- 用裝飾器（decorator）定義工具
- 自動處理 JSON-RPC 通訊
- 自動產生工具描述

### 最簡單的 MCP 伺服器

```python
from fastmcp import FastMCP

# 步驟 1：建立 MCP 伺服器實例
mcp = FastMCP(name="MyFirstServer")

# 步驟 2：定義工具（使用 @mcp.tool 裝飾器）
@mcp.tool
def hello(name: str) -> str:
    """
    向指定的人問好
    
    參數：
        name: 要問候的名字
        
    回傳：
        問候訊息
    """
    return f"Hello, {name}!"

# 步驟 3：啟動伺服器
if __name__ == "__main__":
    mcp.run()
```

**執行：**
```bash
python3 simple_server.py
```

**預期輸出：**
```
MCP Server 'MyFirstServer' running on stdio
```

### 帶參數類型的工具

```python
from fastmcp import FastMCP

mcp = FastMCP(name="MathServer")

@mcp.tool
def add(a: int, b: int) -> int:
    """加法運算"""
    return a + b

@mcp.tool
def multiply(a: float, b: float) -> float:
    """乘法運算"""
    return a * b

if __name__ == "__main__":
    mcp.run()
```

### 實用的檔案操作 MCP 伺服器

```python
from fastmcp import FastMCP
from pathlib import Path
import json

mcp = FastMCP(name="FileServer")

@mcp.tool
def read_file(path: str) -> dict:
    """
    讀取檔案內容
    
    參數：
        path: 檔案路徑
        
    回傳：
        {"content": "檔案內容"} 或 {"error": "錯誤訊息"}
    """
    try:
        file_path = Path(path).expanduser().resolve()
        content = file_path.read_text(encoding="utf-8")
        return {
            "content": content,
            "path": str(file_path),
            "lines": len(content.splitlines())
        }
    except FileNotFoundError:
        return {"error": f"檔案不存在: {path}"}
    except PermissionError:
        return {"error": f"沒有讀取權限: {path}"}
    except Exception as e:
        return {"error": f"讀取失敗: {e}"}

@mcp.tool
def write_file(path: str, content: str) -> dict:
    """
    寫入檔案
    
    參數：
        path: 檔案路徑
        content: 要寫入的內容
        
    回傳：
        {"status": "success"} 或 {"error": "錯誤訊息"}
    """
    try:
        file_path = Path(path).expanduser().resolve()
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8")
        return {
            "status": "success",
            "path": str(file_path),
            "bytes_written": len(content.encode("utf-8"))
        }
    except Exception as e:
        return {"error": f"寫入失敗: {e}"}

@mcp.tool
def list_directory(path: str = ".") -> dict:
    """
    列出目錄內容
    
    參數：
        path: 目錄路徑（預設為當前目錄）
        
    回傳：
        {"files": [...]} 或 {"error": "錯誤訊息"}
    """
    try:
        dir_path = Path(path).expanduser().resolve()
        
        if not dir_path.exists():
            return {"error": f"目錄不存在: {path}"}
        
        if not dir_path.is_dir():
            return {"error": f"不是目錄: {path}"}
        
        files = []
        for item in dir_path.iterdir():
            files.append({
                "name": item.name,
                "type": "dir" if item.is_dir() else "file",
                "size": item.stat().st_size if item.is_file() else None
            })
        
        # 排序：資料夾在前
        files.sort(key=lambda x: (x["type"] == "file", x["name"]))
        
        return {
            "path": str(dir_path),
            "files": files,
            "total": len(files)
        }
    except Exception as e:
        return {"error": f"列出目錄失敗: {e}"}

if __name__ == "__main__":
    mcp.run()
```

## 4.4 連接 MCP 伺服器到 Claude Desktop

### 設定步驟

**步驟 1：找到設定檔**

macOS:
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

Windows:
```
%APPDATA%\Claude\claude_desktop_config.json
```

Linux:
```bash
~/.config/Claude/claude_desktop_config.json
```

**步驟 2：編輯設定檔**

```json
{
  "mcpServers": {
    "file-server": {
      "command": "python3",
      "args": [
        "/absolute/path/to/your/file_server.py"
      ]
    }
  }
}
```

**步驟 3：重新啟動 Claude Desktop**

**步驟 4：測試**

在 Claude Desktop 中輸入：
```
請列出當前目錄的檔案
```

Claude 會自動呼叫您的 MCP 伺服器！

## 4.5 使用 Ollama 建立本地 MCP 伺服器

### 安裝 Ollama

```bash
# macOS / Linux
curl -fsSL https://ollama.com/install.sh | sh

# 驗證安裝
ollama --version

# 下載模型
ollama pull llama3.1:8b
```

### 結合 Ollama 和 FastMCP

```python
from fastmcp import FastMCP
import ollama

mcp = FastMCP(name="OllamaCodeHelper")

@mcp.tool
def generate_code(prompt: str, language: str = "python") -> dict:
    """
    使用本地 LLM 生成程式碼
    
    參數：
        prompt: 程式碼需求描述
        language: 程式語言（預設 python）
        
    回傳：
        {"code": "生成的程式碼", "language": "..."}
    """
    try:
        full_prompt = f"Write {language} code for: {prompt}\nOnly output the code, no explanations."
        
        response = ollama.chat(
            model="llama3.1:8b",
            messages=[
                {"role": "user", "content": full_prompt}
            ]
        )
        
        code = response["message"]["content"]
        
        return {
            "code": code,
            "language": language,
            "model": "llama3.1:8b"
        }
    except Exception as e:
        return {"error": f"程式碼生成失敗: {e}"}

@mcp.tool
def explain_code(code: str) -> dict:
    """
    使用本地 LLM 解釋程式碼
    
    參數：
        code: 要解釋的程式碼
        
    回傳：
        {"explanation": "程式碼說明"}
    """
    try:
        prompt = f"Explain this code in Traditional Chinese:\n\n{code}"
        
        response = ollama.chat(
            model="llama3.1:8b",
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        
        explanation = response["message"]["content"]
        
        return {
            "explanation": explanation,
            "model": "llama3.1:8b"
        }
    except Exception as e:
        return {"error": f"程式碼解釋失敗: {e}"}

if __name__ == "__main__":
    mcp.run()
```

---

# 📚 第五章：實作練習指南

## 5.1 練習 1：完成編碼代理

### 目標

完成 `coding_agent_practice.py` 中的所有 TODO 項目

### TODO 1：實作 resolve_abs_path

**位置：** 第 8 行

**任務：**
```python
def resolve_abs_path(path_str: str) -> Path:
    # TODO: 將相對路徑轉換為絕對路徑
    #  1. 使用 Path(path_str).expanduser() 處理 ~
    #  2. 檢查是否為絕對路徑
    #  3. 如果不是，使用 Path.cwd() 取得當前目錄並拼接
    #  4. 使用 .resolve() 解析路徑
    pass
```

**提示：**
```python
# 範例實作步驟
path = Path(path_str).expanduser()  # 處理 ~
if not path.is_absolute():
    path = (Path.cwd() / path).resolve()
return path
```

**測試：**
```python
# 測試程式碼
print(resolve_abs_path("test.py"))
# 預期輸出: /Users/you/current_dir/test.py

print(resolve_abs_path("~/Desktop/file.txt"))
# 預期輸出: /Users/you/Desktop/file.txt
```

### TODO 2：實作 read_file_tool

**位置：** 第 18 行

**任務：**
```python
def read_file_tool(filename: str) -> Dict[str, Any]:
    # TODO: 實作檔案讀取邏輯
    #  1. 使用 resolve_abs_path 取得絕對路徑
    #  2. 使用 open(...).read() 讀取檔案
    #  3. 處理 FileNotFoundError 和 PermissionError
    #  4. 回傳包含 file_path 和 content 的字典
    pass
```

**完整實作：**
```python
def read_file_tool(filename: str) -> Dict[str, Any]:
    full_path = resolve_abs_path(filename)
    try:
        with open(str(full_path), "r", encoding="utf-8") as f:
            content = f.read()
        return {
            "file_path": str(full_path),
            "content": content
        }
    except FileNotFoundError:
        return {"error": f"檔案不存在: {filename}"}
    except PermissionError:
        return {"error": f"沒有權限: {filename}"}
```

### TODO 3：實作 list_files_tool

**位置：** 第 30 行

**提示：** 使用 `Path.iterdir()` 遍歷目錄

### TODO 4：實作 edit_file_tool

**位置：** 第 42 行

**關鍵邏輯：**
```python
# 建立新檔案
if old_str == "":
    full_path.write_text(new_str, encoding="utf-8")
    return {"action": "created_file"}

# 修改現有檔案
original = full_path.read_text(encoding="utf-8")
edited = original.replace(old_str, new_str, 1)  # 只替換第一次出現
full_path.write_text(edited, encoding="utf-8")
return {"action": "edited"}
```

### TODO 5：實作 extract_tool_invocations

**位置：** 第 75 行

**測試案例：**
```python
text = 'tool: read_file({"filename": "test.py"})'
result = extract_tool_invocations(text)
assert result == [("read_file", {"filename": "test.py"})]
```

### TODO 6：實作 execute_llm_call

**位置：** 第 100 行

**實作：**
```python
def execute_llm_call(conversation: List[Dict[str, str]], model: str = "gpt-4o-mini") -> str:
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    response = client.chat.completions.create(
        model=model,
        messages=conversation,
        max_completion_tokens=2000
    )
    return response.choices[0].message.content
```

### TODO 7：完成主迴圈

**位置：** 第 110 行

**關鍵步驟：**
1. 接收使用者輸入
2. 呼叫 LLM
3. 解析工具呼叫
4. 執行工具
5. 將結果回傳 LLM
6. 重複 2-5

## 5.2 練習 2：建立 MCP 伺服器

### 目標

完成 `mcp_server_practice.py` 中的 MCP 伺服器實作

### TODO 1：建立 FastMCP 實例

**位置：** 第 5 行

```python
# TODO: 建立 FastMCP 實例
#  mcp = FastMCP(name="your-server-name")
```

**實作：**
```python
from fastmcp import FastMCP

mcp = FastMCP(name="FileOperationServer")
```

### TODO 2：實作 read_file 工具

**位置：** 第 10 行

```python
# TODO: 使用 @mcp.tool 裝飾器定義 read_file 工具
#  1. 參數：path (str)
#  2. 回傳：{"content": "..."} 或 {"error": "..."}
#  3. 記得加上 docstring
```

**完整實作：**
```python
@mcp.tool
def read_file(path: str) -> dict:
    """
    讀取檔案內容
    
    參數：
        path: 檔案路徑
        
    回傳：
        包含檔案內容的字典
    """
    try:
        file_path = Path(path).expanduser().resolve()
        content = file_path.read_text(encoding="utf-8")
        return {
            "content": content,
            "path": str(file_path)
        }
    except Exception as e:
        return {"error": str(e)}
```

### TODO 3：實作 write_file 工具

**提示：** 使用 `Path.write_text()`

### TODO 4：實作 list_dir 工具

**提示：** 使用 `Path.iterdir()`

### TODO 5：加入主程式

```python
if __name__ == "__main__":
    mcp.run()
```

## 5.3 測試您的實作

### 測試編碼代理

```bash
# 執行編碼代理
python3 coding_agent_practice.py
```

**測試案例 1：建立檔案**
```
You: 建立一個 test.py，內容是 print('hello')
預期行為: 代理呼叫 edit_file 工具建立檔案
```

**測試案例 2：讀取檔案**
```
You: 讀取 test.py 的內容
預期行為: 代理呼叫 read_file 工具並顯示內容
```

**測試案例 3：列出目錄**
```
You: 列出當前目錄的檔案
預期行為: 代理呼叫 list_files 工具並列出檔案
```

### 測試 MCP 伺服器

```bash
# 執行 MCP 伺服器
python3 mcp_server_practice.py
```

**測試方法 1：使用 Claude Desktop**

1. 設定 `claude_desktop_config.json`
2. 重新啟動 Claude Desktop
3. 在對話中測試：「請列出當前目錄的檔案」

**測試方法 2：使用 MCP Inspector**

```bash
# 安裝 MCP Inspector
npm install -g @modelcontextprotocol/inspector

# 執行 Inspector
mcp-inspector python3 mcp_server_practice.py
```

---

# 📚 第六章：除錯與最佳實踐

## 6.1 常見問題與解決方案

### 問題 1：JSON 解析錯誤

**錯誤訊息：**
```
[錯誤] JSON 解析失敗: tool: read_file({'filename': 'test.py'})
```

**原因：** 使用了單引號而非雙引號

**解決方案：**
在系統提示詞中明確說明：
```python
SYSTEM_PROMPT = """
**重要：JSON 必須使用雙引號**

✅ 正確: tool: read_file({"filename": "test.py"})
❌ 錯誤: tool: read_file({'filename': 'test.py'})
"""
```

### 問題 2：工具無限迴圈

**現象：** 代理不斷呼叫相同的工具

**原因：** 工具結果格式不清楚

**解決方案：**
```python
# 明確的工具結果格式
result = {
    "status": "success",  # 明確的狀態
    "content": "...",     # 實際內容
    "message": "操作完成"  # 人類可讀的訊息
}

# 回傳給 LLM
conversation.append({
    "role": "user",
    "content": f"tool_result({json.dumps(result, ensure_ascii=False)})"
})
```

### 問題 3：路徑解析錯誤

**現象：** 找不到檔案或建立在錯誤的位置

**原因：** 相對路徑處理不當

**解決方案：**
```python
def resolve_abs_path(path_str: str) -> Path:
    """
    統一的路徑解析函式
    處理：
    1. ~ 展開
    2. 相對路徑轉絕對路徑
    3. . 和 .. 解析
    """
    path = Path(path_str).expanduser()
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    return path
```

### 問題 4：編碼問題

**現象：** 中文亂碼

**解決方案：**
```python
# 讀取檔案
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 寫入檔案
with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

# JSON 序列化
json.dumps(data, ensure_ascii=False)  # 保留非 ASCII 字元
```

## 6.2 最佳實踐

### 1. 系統提示詞設計

**✅ 好的範例：**
```python
SYSTEM_PROMPT = """
你是一個編碼助手。

可用工具：
{tool_list}

工具呼叫格式（精確遵守）：
tool: TOOL_NAME({{"param": "value"}})

規則：
1. 一次只呼叫一個工具
2. 收到 tool_result 後繼續任務
3. 使用雙引號的緊湊 JSON
4. 不需要工具時正常回應

範例：
tool: read_file({{"filename": "test.py"}})
"""
```

**❌ 不好的範例：**
```python
# 太簡單，沒有格式說明
SYSTEM_PROMPT = "你是助手，可以使用工具。"

# 太複雜，LLM 容易混淆
SYSTEM_PROMPT = """
你可以使用工具，格式是...
或者你也可以...
有時候你應該...
但如果...則...
除非...否則...
"""
```

### 2. 錯誤處理

**完整的錯誤處理範例：**
```python
def read_file_tool(filename: str) -> Dict[str, Any]:
    try:
        full_path = resolve_abs_path(filename)
    except Exception as e:
        return {
            "error": "path_resolution_failed",
            "message": f"路徑解析失敗: {e}",
            "input": filename
        }
    
    try:
        content = full_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {
            "error": "file_not_found",
            "message": f"檔案不存在: {filename}",
            "resolved_path": str(full_path)
        }
    except PermissionError:
        return {
            "error": "permission_denied",
            "message": f"沒有讀取權限: {filename}",
            "resolved_path": str(full_path)
        }
    except UnicodeDecodeError:
        return {
            "error": "encoding_error",
            "message": f"檔案編碼錯誤（可能是二進位檔案）: {filename}"
        }
    except Exception as e:
        return {
            "error": "unknown_error",
            "message": f"未知錯誤: {e}",
            "type": type(e).__name__
        }
    
    return {
        "file_path": str(full_path),
        "content": content,
        "lines": len(content.splitlines()),
        "size": len(content)
    }
```

### 3. 日誌與除錯

**添加除錯輸出：**
```python
# 在關鍵步驟添加日誌
def execute_llm_call(conversation, model="gpt-4o-mini"):
    print(f"\n[DEBUG] 呼叫 LLM，對話長度: {len(conversation)}")
    print(f"[DEBUG] 最後一則訊息: {conversation[-1]['content'][:100]}...")
    
    response = client.chat.completions.create(
        model=model,
        messages=conversation
    )
    
    result = response.choices[0].message.content
    print(f"[DEBUG] LLM 回應長度: {len(result)} 字元")
    print(f"[DEBUG] 回應前 100 字元: {result[:100]}")
    
    return result
```

**使用顏色輸出：**
```python
# ANSI 顏色碼
RED = '\033[91m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

# 使用範例
print(f"{GREEN}[成功]{RESET} 檔案已建立")
print(f"{RED}[錯誤]{RESET} 找不到檔案")
print(f"{YELLOW}[警告]{RESET} API 配額即將用盡")
print(f"{BLUE}[資訊]{RESET} 正在處理...")
```

### 4. 測試策略

**單元測試範例：**
```python
import unittest

class TestToolFunctions(unittest.TestCase):
    def setUp(self):
        """每個測試前執行"""
        self.test_file = Path("test_temp.txt")
        
    def tearDown(self):
        """每個測試後清理"""
        if self.test_file.exists():
            self.test_file.unlink()
    
    def test_read_file_success(self):
        """測試成功讀取檔案"""
        # 準備測試資料
        self.test_file.write_text("test content")
        
        # 執行函式
        result = read_file_tool(str(self.test_file))
        
        # 驗證結果
        self.assertIn("content", result)
        self.assertEqual(result["content"], "test content")
        self.assertNotIn("error", result)
    
    def test_read_file_not_found(self):
        """測試讀取不存在的檔案"""
        result = read_file_tool("nonexistent.txt")
        
        self.assertIn("error", result)
        self.assertEqual(result["error"], "file_not_found")
    
    def test_edit_file_create(self):
        """測試建立新檔案"""
        result = edit_file_tool(
            str(self.test_file),
            "",
            "new content"
        )
        
        self.assertEqual(result["action"], "created_file")
        self.assertTrue(self.test_file.exists())
        self.assertEqual(self.test_file.read_text(), "new content")

if __name__ == "__main__":
    unittest.main()
```

**執行測試：**
```bash
python3 -m unittest test_tools.py
```

---

# 📚 第七章：進階主題

## 7.1 效能優化

### 1. 減少 API 呼叫次數

**問題：** 頻繁呼叫 LLM 導致成本高昂

**解決方案：** 批次處理工具呼叫

```python
# 允許 LLM 一次呼叫多個工具
SYSTEM_PROMPT = """
你可以一次呼叫多個工具，每個工具呼叫佔一行：

tool: read_file({{"filename": "a.py"}})
tool: read_file({{"filename": "b.py"}})
tool: list_files({{"path": "."}})
"""

# 解析多個工具呼叫
def extract_tool_invocations(text: str) -> List[Tuple[str, Dict]]:
    invocations = []
    for line in text.splitlines():
        if line.startswith("tool:"):
            # ... 解析邏輯
            invocations.append((tool_name, args))
    return invocations
```

### 2. 快取常用結果

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def read_file_cached(filename: str) -> str:
    """
    快取檔案內容（適用於不常變動的檔案）
    """
    with open(filename, "r") as f:
        return f.read()

# 使用
content1 = read_file_cached("config.json")  # 讀取檔案
content2 = read_file_cached("config.json")  # 使用快取（快）
```

### 3. 限制對話長度

```python
MAX_CONVERSATION_LENGTH = 20

def trim_conversation(conversation: List[Dict]) -> List[Dict]:
    """
    保留最近的 N 則訊息
    始終保留 system 訊息
    """
    if len(conversation) <= MAX_CONVERSATION_LENGTH:
        return conversation
    
    # 保留第一則（system）+ 最近的 N-1 則
    return [conversation[0]] + conversation[-(MAX_CONVERSATION_LENGTH-1):]
```

## 7.2 安全性考量

### 1. 路徑遍歷攻擊防護

```python
def is_safe_path(base_dir: Path, target_path: Path) -> bool:
    """
    檢查目標路徑是否在基礎目錄內（防止 ../ 攻擊）
    """
    try:
        target_path.resolve().relative_to(base_dir.resolve())
        return True
    except ValueError:
        return False

# 使用範例
BASE_DIR = Path.cwd()

def safe_read_file(filename: str) -> Dict:
    full_path = resolve_abs_path(filename)
    
    if not is_safe_path(BASE_DIR, full_path):
        return {
            "error": "permission_denied",
            "message": "不允許存取該路徑（安全限制）"
        }
    
    # ... 正常讀取
```

### 2. 命令注入防護

```python
# ❌ 危險：直接執行使用者輸入
import os
def run_command(cmd: str):
    os.system(cmd)  # 使用者可輸入 "rm -rf /"

# ✅ 安全：使用白名單
ALLOWED_COMMANDS = {
    "list": ["ls", "-la"],
    "pwd": ["pwd"],
    "whoami": ["whoami"]
}

def safe_run_command(cmd_name: str) -> str:
    if cmd_name not in ALLOWED_COMMANDS:
        return "不允許的命令"
    
    import subprocess
    result = subprocess.run(
        ALLOWED_COMMANDS[cmd_name],
        capture_output=True,
        text=True
    )
    return result.stdout
```

### 3. API Key 保護

```python
# ✅ 使用環境變數
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.environ["OPENAI_API_KEY"]

# ✅ 驗證 API Key 格式
def validate_api_key(key: str) -> bool:
    return key.startswith("sk-") and len(key) > 20

# ❌ 不要將 API Key 硬編碼
api_key = "sk-1234567890abcdef"  # 危險！
```

## 7.3 擴展功能

### 1. 添加新工具

```python
# 範例：新增搜尋工具
@mcp.tool
def search_in_file(filename: str, pattern: str) -> dict:
    """
    在檔案中搜尋符合模式的行
    
    參數：
        filename: 檔案路徑
        pattern: 搜尋模式（支援正則表達式）
        
    回傳：
        符合的行號和內容
    """
    import re
    
    try:
        full_path = resolve_abs_path(filename)
        content = full_path.read_text(encoding="utf-8")
        
        matches = []
        for i, line in enumerate(content.splitlines(), 1):
            if re.search(pattern, line):
                matches.append({
                    "line_number": i,
                    "content": line.strip()
                })
        
        return {
            "filename": str(full_path),
            "pattern": pattern,
            "matches": matches,
            "count": len(matches)
        }
    except Exception as e:
        return {"error": str(e)}
```

### 2. 多模型支援

```python
class MultiModelAgent:
    def __init__(self):
        self.models = {
            "gpt4": "gpt-4o-mini",
            "gpt3": "gpt-3.5-turbo",
            "ollama": "llama3.1:8b"
        }
        self.current_model = "gpt4"
    
    def call_llm(self, conversation: List[Dict]) -> str:
        if self.current_model == "ollama":
            return self._call_ollama(conversation)
        else:
            return self._call_openai(conversation)
    
    def _call_openai(self, conversation: List[Dict]) -> str:
        client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
        response = client.chat.completions.create(
            model=self.models[self.current_model],
            messages=conversation
        )
        return response.choices[0].message.content
    
    def _call_ollama(self, conversation: List[Dict]) -> str:
        import ollama
        response = ollama.chat(
            model=self.models["ollama"],
            messages=conversation
        )
        return response["message"]["content"]
    
    def switch_model(self, model_name: str):
        if model_name in self.models:
            self.current_model = model_name
            print(f"已切換到模型: {model_name}")
        else:
            print(f"未知的模型: {model_name}")
```

### 3. 持久化對話

```python
import json
from datetime import datetime

class ConversationManager:
    def __init__(self, save_dir="conversations"):
        self.save_dir = Path(save_dir)
        self.save_dir.mkdir(exist_ok=True)
    
    def save_conversation(self, conversation: List[Dict], session_id: str = None):
        """儲存對話到檔案"""
        if not session_id:
            session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        filename = self.save_dir / f"conversation_{session_id}.json"
        
        with open(filename, "w", encoding="utf-8") as f:
            json.dump({
                "session_id": session_id,
                "timestamp": datetime.now().isoformat(),
                "messages": conversation
            }, f, ensure_ascii=False, indent=2)
        
        print(f"對話已儲存: {filename}")
    
    def load_conversation(self, session_id: str) -> List[Dict]:
        """從檔案載入對話"""
        filename = self.save_dir / f"conversation_{session_id}.json"
        
        if not filename.exists():
            raise FileNotFoundError(f"找不到對話: {session_id}")
        
        with open(filename, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        print(f"已載入對話: {session_id}")
        return data["messages"]
    
    def list_conversations(self) -> List[str]:
        """列出所有儲存的對話"""
        sessions = []
        for file in self.save_dir.glob("conversation_*.json"):
            with open(file, "r") as f:
                data = json.load(f)
                sessions.append({
                    "session_id": data["session_id"],
                    "timestamp": data["timestamp"],
                    "message_count": len(data["messages"])
                })
        return sessions

# 使用範例
manager = ConversationManager()

# 儲存對話
manager.save_conversation(conversation, "my_session")

# 載入對話
conversation = manager.load_conversation("my_session")

# 列出所有對話
all_sessions = manager.list_conversations()
print(json.dumps(all_sessions, indent=2, ensure_ascii=False))
```

## 7.4 整合其他服務

### 1. 整合 GitHub API

```python
@mcp.tool
def create_github_issue(repo: str, title: str, body: str) -> dict:
    """
    在 GitHub 倉庫中建立 issue
    
    參數：
        repo: 倉庫名稱（格式：owner/repo）
        title: Issue 標題
        body: Issue 內容
        
    回傳：
        建立的 issue 資訊
    """
    import requests
    
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        return {"error": "未設定 GITHUB_TOKEN"}
    
    url = f"https://api.github.com/repos/{repo}/issues"
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    data = {
        "title": title,
        "body": body
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 201:
        issue = response.json()
        return {
            "success": True,
            "issue_number": issue["number"],
            "url": issue["html_url"]
        }
    else:
        return {
            "error": f"建立失敗: {response.status_code}",
            "message": response.json().get("message", "")
        }
```

### 2. 整合資料庫

```python
import sqlite3

@mcp.tool
def query_database(query: str) -> dict:
    """
    執行 SQL 查詢（只讀）
    
    參數：
        query: SQL 查詢語句
        
    回傳：
        查詢結果
    """
    # 安全檢查：只允許 SELECT
    if not query.strip().upper().startswith("SELECT"):
        return {"error": "只允許 SELECT 查詢"}
    
    try:
        conn = sqlite3.connect("database.db")
        cursor = conn.cursor()
        
        cursor.execute(query)
        
        # 取得欄位名稱
        columns = [description[0] for description in cursor.description]
        
        # 取得所有結果
        rows = cursor.fetchall()
        
        # 轉換為字典列表
        results = [
            dict(zip(columns, row))
            for row in rows
        ]
        
        conn.close()
        
        return {
            "success": True,
            "row_count": len(results),
            "results": results
        }
    except Exception as e:
        return {"error": str(e)}
```

---

# 📚 附錄

## A. 快速參考

### 系統提示詞範本

```python
SYSTEM_PROMPT = """
你是一個專業的編碼助手。

可用工具：
{tool_list_repr}

工具呼叫格式：
tool: TOOL_NAME({{"param": "value"}})

規則：
1. 一次一個工具
2. 使用雙引號的緊湊 JSON
3. 收到 tool_result 後繼續
4. 不需要工具時正常回應

範例：
tool: read_file({{"filename": "test.py"}})
"""
```

### 常用工具簽名

```python
def read_file(filename: str) -> Dict[str, Any]
def list_files(path: str) -> Dict[str, Any]
def edit_file(path: str, old_str: str, new_str: str) -> Dict[str, Any]
def search_file(filename: str, pattern: str) -> Dict[str, Any]
def execute_command(command: str) -> Dict[str, Any]
```

### MCP 伺服器範本

```python
from fastmcp import FastMCP

mcp = FastMCP(name="ServerName")

@mcp.tool
def tool_name(param: str) -> dict:
    """工具說明"""
    try:
        # 實作邏輯
        return {"result": "..."}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    mcp.run()
```

## B. 術語表

| 術語 | 英文 | 說明 |
|------|------|------|
| 編碼代理 | Coding Agent | 能使用工具執行編碼任務的 AI 系統 |
| 工具呼叫 | Tool Calling | LLM 決定並執行外部函式的機制 |
| MCP | Model Context Protocol | 統一 AI 應用與資料源連接的標準協議 |
| 系統提示詞 | System Prompt | 定義 AI 行為和能力的初始指令 |
| 對話歷史 | Conversation History | LLM 用來理解上下文的訊息序列 |
| FastMCP | FastMCP | Python 框架，簡化 MCP 伺服器開發 |
| JSON-RPC | JSON-RPC | MCP 底層使用的通訊協議 |
| 裝飾器 | Decorator | Python 語法，用於修改函式行為（如 @mcp.tool） |

## C. 常見錯誤碼

| 錯誤碼 | 說明 | 解決方案 |
|--------|------|---------|
| file_not_found | 檔案不存在 | 檢查路徑是否正確，使用絕對路徑 |
| permission_denied | 沒有權限 | 檢查檔案權限，使用 chmod 修改 |
| json_decode_error | JSON 格式錯誤 | 確保使用雙引號，檢查括號閉合 |
| encoding_error | 編碼錯誤 | 確保使用 UTF-8 編碼 |
| path_not_absolute | 路徑不是絕對路徑 | 使用 resolve_abs_path() 轉換 |

## D. 進階資源

### 官方文件
- OpenAI API: https://platform.openai.com/docs
- FastMCP: https://github.com/jlowin/fastmcp
- Anthropic MCP: https://modelcontextprotocol.io
- Ollama: https://ollama.com/docs

### 進階閱讀
1. **Tool Calling 深入指南**
   - Function Calling 最佳實踐
   - 錯誤處理策略
   - 效能優化技巧

2. **MCP 協議規範**
   - JSON-RPC 2.0 標準
   - MCP 訊息格式
   - 安全性考量

3. **AI Agent 設計模式**
   - ReAct (Reasoning + Acting)
   - Chain-of-Thought
   - Self-Reflection

---

# 🎓 結語

恭喜您完成 Week 2 的完整學習！

您現在已經掌握：
- ✅ 建構功能完整的編碼代理
- ✅ 理解工具呼叫的原理和實作
- ✅ 使用 FastMCP 建立 MCP 伺服器
- ✅ 整合本地和雲端 LLM
- ✅ 除錯和優化 Agent 系統

**下一步：**
1. 完成 Week 2 的作業
2. 嘗試添加自己的工具
3. 整合到實際專案中
4. 分享您的實作經驗

**需要幫助？**
- 查看範例程式碼：`coding_agent_practice.py`
- 參考講義：`data/lecture_*.txt`
- 重新閱讀相關章節

祝您學習愉快！🚀
