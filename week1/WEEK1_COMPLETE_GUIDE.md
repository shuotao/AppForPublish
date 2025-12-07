# 📚 史丹佛 Week 1：LLM 提示工程完整學習指南

**課程代碼：** CS146S | **授課教授：** Mihail Eric  
**大學：** Stanford University, Fall 2025

---

# 🎯 這份指南的目標

這份指南專為**程式設計初學者**設計。我們會：

1. ✅ 解釋所有專業術語（用日常語言）
2. ✅ 提供完整的程式碼範例（可直接複製執行）
3. ✅ 展示每個步驟的預期結果
4. ✅ 讓您能夠從零開始，完成所有 6 個作業

---

# 📖 第一章：什麼是 LLM？（5 分鐘快速理解）

## 1.1 LLM 是什麼？

**LLM = Large Language Model = 大型語言模型**

想像您有一個非常聰明的朋友：
- 他讀過幾乎整個網路上的文字
- 他可以回答問題、寫程式碼、翻譯語言
- 但他有時會**編造**不存在的東西（這叫「幻覺」）

**常見的 LLM：**
- ChatGPT（OpenAI 製作）
- Claude（Anthropic 製作）
- Llama（Meta 製作，我們這週會用這個）

## 1.2 提示工程是什麼？

**提示工程 = Prompt Engineering = 設計「怎麼問 AI」的技術**

就像問人問題：
```
❌ 壞的問法：「寫個程式」
  → AI 不知道您要什麼程式

✅ 好的問法：「寫一個 Python 函式，輸入一個數字列表，回傳最大的數字」
  → AI 知道您要什麼
```

**這週您會學 6 種「問 AI」的技術：**

| 技巧 | 用途 | 比喻 |
|------|------|------|
| 1. 思考鏈 | 讓 AI 展示推理步驟 | 像數學考試要「寫計算過程」 |
| 2. Few-shot | 給 AI 範例來學習 | 像給小孩看例子教他做事 |
| 3. 工具呼叫 | 讓 AI 使用外部工具 | 像讓 AI 用計算機 |
| 4. 自洽性 | 問 AI 多次，取多數答案 | 像陪審團投票 |
| 5. RAG | 給 AI 參考資料 | 像開書考試 |
| 6. 反思 | 讓 AI 檢查並改進答案 | 像老師批改作業後讓學生訂正 |

---

# 🛠️ 第二章：環境設定（必做！）

## 2.1 什麼是 Ollama？

**Ollama** 是一個工具，讓您在**自己的電腦**上執行 AI 模型。

```
為什麼用 Ollama？
├─ ✅ 免費
├─ ✅ 不需要網路（下載模型後）
├─ ✅ 隱私（您的資料不會上傳）
└─ ✅ 沒有 API 費用
```

## 2.2 安裝 Ollama（按照您的系統選擇）

### macOS 用戶（使用 Homebrew）

```bash
# 步驟 1：安裝 Ollama
brew install --cask ollama

# 步驟 2：確認安裝成功
ollama -v
# 應該看到類似 "ollama version 0.x.x"
```

### Windows 用戶

1. 打開瀏覽器，前往 https://ollama.com/download
2. 下載 Windows 版本
3. 執行安裝程式，一路點「下一步」

### Linux 用戶

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

## 2.3 下載 AI 模型（只需做一次）

```bash
# 下載第一個模型（約 4.7 GB，需要幾分鐘）
ollama pull llama3.1:8b

# 下載第二個模型（約 7.1 GB）
ollama pull mistral-nemo:12b
```

**等待下載完成**，您會看到進度條。

## 2.4 啟動 Ollama 服務（每次使用前都要做）

```bash
ollama serve
```

**成功的畫面：**
```
Listening on 127.0.0.1:11434
```

⚠️ **重要：** 保持這個終端視窗開啟！開另一個終端視窗來執行程式碼。

## 2.5 測試是否正常運作

開啟**新的終端視窗**，輸入：

```bash
ollama run llama3.1:8b "1+1等於多少？"
```

**預期結果：** AI 會回答「2」或類似的答案。

## 2.6 安裝 Python 套件

```bash
pip3 install ollama python-dotenv
```

---

# 📚 第三章：6 種提示技巧詳解

---

## 技巧 1️⃣：思考鏈（Chain of Thought）

### 📁 檔案位置
```
week1/chain_of_thought.py
```

### 🎯 這個練習在做什麼？

**任務：** 讓 AI 計算 $3^{12345} \mod 100$

**白話文翻譯：**
```
「3 的 12345 次方」除以「100」的餘數是多少？
```

### 🔢 先用簡單例子理解「mod」

**mod = 取餘數（除法後剩下的數字）**

```
17 mod 5 = ?

計算過程：
17 ÷ 5 = 3 餘 2
      ↓
答案：17 mod 5 = 2
```

更多例子：
```
10 mod 3 = 1    （10 ÷ 3 = 3 餘 1）
100 mod 7 = 2   （100 ÷ 7 = 14 餘 2）
15 mod 5 = 0    （15 ÷ 5 = 3 餘 0，整除）
```

### 🤔 為什麼不能直接計算 $3^{12345}$？

```
3^1 = 3
3^2 = 9
3^3 = 27
3^4 = 81
3^5 = 243
3^10 = 59,049
3^20 = 3,486,784,401
...
3^12345 = ？？？（這個數字有幾千位數！電腦算不出來）
```

**解決方法：找規律！**

我們只關心「除以 100 的餘數」，所以只需要看最後兩位數：

```
3^1  mod 100 = 3
3^2  mod 100 = 9
3^3  mod 100 = 27
3^4  mod 100 = 81
3^5  mod 100 = 43   ← 243 的最後兩位
3^6  mod 100 = 29   ← 729 的最後兩位
3^7  mod 100 = 87
3^8  mod 100 = 61
3^9  mod 100 = 83
3^10 mod 100 = 49
...
3^20 mod 100 = 1    ← 規律！每 20 次循環

因為規律每 20 次循環：
12345 ÷ 20 = 617 餘 5
所以 3^12345 mod 100 = 3^5 mod 100 = 43
```

**正確答案：43**

### 📝 什麼是「思考鏈」？

**思考鏈 = 讓 AI 展示推理步驟，而不是直接給答案**

```
❌ 沒有思考鏈：
問：3^12345 mod 100 = ?
答：43

✅ 有思考鏈：
問：3^12345 mod 100 = ?
答：讓我逐步思考...
    步驟 1：這個數字太大，不能直接計算
    步驟 2：我需要找規律
    步驟 3：計算 3 的幾次方 mod 100...
    步驟 4：發現每 20 次會重複...
    步驟 5：12345 = 20 × 617 + 5
    步驟 6：所以答案和 3^5 mod 100 相同
    Answer: 43
```

### 🎓 重要概念：思考鏈是「維度」，不是獨立技巧

**思考鏈可以和其他技巧結合使用：**

```
思考鏈 + Few-shot：
  範例 1：反轉 "hello"
  思考：h-e-l-l-o → 倒著讀 → o-l-l-e-h
  答案：olleh

思考鏈 + RAG：
  文件：API 使用 X-API-Key 認證
  思考：文件說要用 X-API-Key，我需要在 header 加入...

思考鏈 + 反思：
  第一次答案錯了
  思考：測試失敗是因為...，我應該修改...
```

### 💻 完整程式碼解析

```python
import os
import re
from dotenv import load_dotenv
from ollama import chat  # 這是和 Ollama 溝通的函式庫

load_dotenv()  # 載入環境變數（如果有的話）

NUM_RUNS_TIMES = 5  # 最多嘗試 5 次

# ═══════════════════════════════════════════════════════════
# 🎯 這是您需要修改的部分！
# ═══════════════════════════════════════════════════════════
YOUR_SYSTEM_PROMPT = """
你是一位數學專家。解決問題時，請逐步思考：

1. 分析問題
2. 將大問題分成小步驟
3. 展示每一步計算
4. 最後給出答案

格式：最後一行必須是 "Answer: <數字>"
"""

# ═══════════════════════════════════════════════════════════
# 這是 AI 收到的問題（不要改）
# ═══════════════════════════════════════════════════════════
USER_PROMPT = """
Solve this problem, then give the final answer on the last line as "Answer: <number>".

what is 3^{12345} (mod 100)?
"""

# ═══════════════════════════════════════════════════════════
# 正確答案（用來檢查 AI 是否答對）
# ═══════════════════════════════════════════════════════════
EXPECTED_OUTPUT = "Answer: 43"


def extract_final_answer(text: str) -> str:
    """
    從 AI 的回答中提取 "Answer: ..." 這一行
    
    例如：
    輸入："讓我計算...blah blah...Answer: 43"
    輸出："Answer: 43"
    """
    # re.findall 是正則表達式函式，用來在文字中尋找特定格式
    # (?mi) = 多行模式 + 不分大小寫
    # ^\s*answer\s*:\s*(.+)\s*$ = 尋找 "Answer: xxx" 格式
    matches = re.findall(r"(?mi)^\s*answer\s*:\s*(.+)\s*$", text)
    if matches:
        value = matches[-1].strip()  # 取最後一個匹配（可能有多個）
        # 從答案中提取數字
        num_match = re.search(r"-?\d+(?:\.\d+)?", value.replace(",", ""))
        if num_match:
            return f"Answer: {num_match.group(0)}"
        return f"Answer: {value}"
    return text.strip()


def test_your_prompt(system_prompt: str) -> bool:
    """
    測試您設計的提示是否能讓 AI 答對
    
    流程：
    1. 將「系統提示」和「問題」發送給 AI
    2. 檢查 AI 的回答是否包含正確答案
    3. 最多嘗試 5 次（因為 AI 有隨機性）
    """
    for idx in range(NUM_RUNS_TIMES):
        print(f"第 {idx + 1} 次嘗試（共 {NUM_RUNS_TIMES} 次）")
        
        # 和 AI 對話
        response = chat(
            model="llama3.1:8b",  # 使用的 AI 模型
            messages=[
                {"role": "system", "content": system_prompt},  # 系統提示
                {"role": "user", "content": USER_PROMPT},      # 問題
            ],
            options={"temperature": 0.3},  # 0.3 = 比較穩定的回答
        )
        
        # 獲取 AI 的回答
        output_text = response.message.content
        final_answer = extract_final_answer(output_text)
        
        # 檢查是否正確
        if final_answer.strip() == EXPECTED_OUTPUT.strip():
            print("✅ SUCCESS - 答對了！")
            return True
        else:
            print(f"❌ 期望答案: {EXPECTED_OUTPUT}")
            print(f"   實際答案: {final_answer}")
    
    return False


# 程式入口點
if __name__ == "__main__":
    test_your_prompt(YOUR_SYSTEM_PROMPT)
```

### 📖 程式碼術語解釋

| 術語 | 說明 |
|------|------|
| `import` | 載入外部函式庫（像是從工具箱拿工具） |
| `def` | 定義一個函式（function） |
| `for idx in range(5)` | 迴圈執行 5 次，idx 依序是 0, 1, 2, 3, 4 |
| `if __name__ == "__main__"` | Python 的標準寫法，表示「直接執行這個檔案時才跑這段」 |
| `return` | 函式結束，把結果送出去 |
| `strip()` | 去除字串前後的空白 |

### ▶️ 如何執行

```bash
# 確保您在 week1 資料夾中
cd week1

# 執行程式
python3 chain_of_thought.py
```

### ✅ 成功的畫面

```
第 1 次嘗試（共 5 次）
✅ SUCCESS - 答對了！
```

### ❌ 失敗的畫面

```
第 1 次嘗試（共 5 次）
❌ 期望答案: Answer: 43
   實際答案: Answer: 27
第 2 次嘗試（共 5 次）
❌ 期望答案: Answer: 43
   實際答案: Answer: 81
...
```

**如果失敗：** 修改 `YOUR_SYSTEM_PROMPT`，加入更多「逐步思考」的指導。

---

## 技巧 2️⃣：Few-shot 提示（提供範例學習）

### 📁 檔案位置
```
week1/k_shot_prompting.py
```

### 📝 名詞釐清：Few-shot vs K-shot vs Multi-shot

```
這三個名詞是同一個意思！

Few-shot = K-shot = Multi-shot = 提供範例讓 AI 學習

「K」是數學上表示「任意數量」的符號
「Few」是「幾個」的意思
「Multi」是「多個」的意思

檔案叫 k_shot_prompting.py，但這週我們統一用「Few-shot」這個名稱
```

### 🎯 這個練習在做什麼？

**任務：** 讓 AI 反轉一個單字

```
輸入：httpstatus
輸出：sutatsptth
       ↑
       (把字母順序倒過來)
```

### 🔤 為什麼 AI 容易搞錯？

AI 擅長「語言」，但不擅長「字元操作」：

```
人類看 "hello"：h-e-l-l-o（5 個字母）
AI 看 "hello"：一個「單詞」的概念

所以 AI 反轉 "hello" 時可能會：
❌ 輸出 "olleh"（其實這是對的，但複雜的字就會錯）
❌ 輸出 "lehlo"（搞混了）
❌ 輸出 "hello"（根本沒反轉）
```

### 📝 什麼是「Few-shot 提示」？

**Few-shot = 給 AI 幾個範例，讓它學會怎麼做**

```
❌ Zero-shot（沒有範例）：
問：反轉 "httpstatus"
答：（AI 可能搞錯）

✅ Few-shot（有範例）：
系統提示：
  你是一個字串反轉專家。
  範例 1：hello → olleh
  範例 2：world → dlrow
  範例 3：python → nohtyp
  
問：反轉 "httpstatus"
答：sutatsptth ✓
```

### 💻 完整程式碼解析

```python
import os
from dotenv import load_dotenv
from ollama import chat

load_dotenv()

NUM_RUNS_TIMES = 5

# ═══════════════════════════════════════════════════════════
# 🎯 這是您需要修改的部分！
# ═══════════════════════════════════════════════════════════
YOUR_SYSTEM_PROMPT = """
你是一個字串反轉專家。你的任務是將單字的字母順序完全倒過來。

以下是一些範例：

範例 1：
輸入：hello
輸出：olleh

範例 2：
輸入：world
輸出：dlrow

範例 3：
輸入：python
輸出：nohtyp

範例 4：
輸入：abc
輸出：cba

規則：
- 只輸出反轉後的結果
- 不要輸出任何其他文字
- 不要加引號
"""

# ═══════════════════════════════════════════════════════════
# 這是 AI 收到的問題（不要改）
# ═══════════════════════════════════════════════════════════
USER_PROMPT = """
Reverse the order of letters in the following word. Only output the reversed word, no other text:

httpstatus
"""

# ═══════════════════════════════════════════════════════════
# 正確答案
# ═══════════════════════════════════════════════════════════
EXPECTED_OUTPUT = "sutatsptth"


def test_your_prompt(system_prompt: str) -> bool:
    """測試您的 few-shot 提示是否有效"""
    for idx in range(NUM_RUNS_TIMES):
        print(f"第 {idx + 1} 次嘗試（共 {NUM_RUNS_TIMES} 次）")
        
        response = chat(
            model="mistral-nemo:12b",  # 這題用 Mistral 模型
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": USER_PROMPT},
            ],
            options={"temperature": 0.5},
        )
        
        output_text = response.message.content.strip()
        
        if output_text.strip() == EXPECTED_OUTPUT.strip():
            print("✅ SUCCESS")
            return True
        else:
            print(f"❌ 期望: {EXPECTED_OUTPUT}")
            print(f"   實際: {output_text}")
    
    return False


if __name__ == "__main__":
    test_your_prompt(YOUR_SYSTEM_PROMPT)
```

### 💡 Few-shot 的關鍵技巧

```
技巧 1：範例要多樣化
  ✅ 好：hello, world, python, abc（長度不同）
  ❌ 壞：aaa, bbb, ccc（太相似）

技巧 2：範例要清晰
  ✅ 好：
      輸入：hello
      輸出：olleh
  
  ❌ 壞：
      hello -> olleh（格式不清楚）

技巧 3：範例數量 2-5 個就夠了
  太少 → AI 學不會
  太多 → 浪費空間，AI 可能混亂
```

### ▶️ 執行指令

```bash
cd week1
python3 k_shot_prompting.py
```

---

## 技巧 3️⃣：工具呼叫（Tool Calling）

### 📁 檔案位置
```
week1/tool_calling.py
```

### 🎯 這個練習在做什麼？

**任務：** 讓 AI 產生正確的「工具呼叫指令」

### 🔧 什麼是「工具呼叫」？

想像 AI 是一個秘書：
- AI 很聰明，但**不能直接操作電腦**
- 如果 AI 想查資料，它必須**告訴您怎麼查**
- 然後**您執行**，再把結果告訴 AI

```
場景：您想知道今天台北的天氣

沒有工具呼叫：
  您：今天台北天氣如何？
  AI：讓我猜猜...大概 25 度晴天？（可能是編造的！）

有工具呼叫：
  您：今天台北天氣如何？
  AI：我需要查詢天氣 API，請執行：
      {"tool": "get_weather", "args": {"city": "taipei"}}
  
  [系統執行工具，獲得真實數據]
  
  AI：根據查詢結果，台北今天 22 度，多雲。
```

### 🎯 這個練習的具體任務

AI 需要產生這樣的 JSON：

```json
{
  "tool": "output_every_func_return_type",
  "args": {
    "file_path": ""
  }
}
```

**JSON 欄位說明：**
- `tool`：要呼叫的工具名稱
- `args`：工具需要的參數（arguments 的縮寫）
- `file_path`：檔案路徑，這裡可以是空字串

### 💻 簡化版程式碼解析

```python
import ast
import json
import re
from ollama import chat

# ═══════════════════════════════════════════════════════════
# 這是可用的工具定義
# ═══════════════════════════════════════════════════════════
def output_every_func_return_type(file_path: str = None) -> str:
    """
    這個工具會分析 Python 檔案，列出所有函式和它們的回傳型別
    
    例如：分析一個有 add() 和 greet() 函式的檔案
    會回傳：
      add: int
      greet: str
    """
    # ... 實作細節（使用 AST 解析 Python 程式碼）
    pass

# 工具清單（把工具名稱對應到實際函式）
TOOL_REGISTRY = {
    "output_every_func_return_type": output_every_func_return_type,
}

# ═══════════════════════════════════════════════════════════
# 🎯 這是您需要修改的部分！
# ═══════════════════════════════════════════════════════════
YOUR_SYSTEM_PROMPT = """
你是一個工具呼叫助手。你可以使用以下工具：

工具名稱：output_every_func_return_type
用途：分析 Python 檔案中所有函式的回傳型別
參數：file_path (字串) - 要分析的檔案路徑，可以為空字串

當使用者要求呼叫工具時，請輸出 JSON 格式：
{
  "tool": "工具名稱",
  "args": {
    "參數名": "參數值"
  }
}

只輸出 JSON，不要輸出其他文字。
"""

# ═══════════════════════════════════════════════════════════
# 測試函式
# ═══════════════════════════════════════════════════════════
def test_your_prompt(system_prompt: str) -> bool:
    """測試 AI 是否能產生正確的工具呼叫"""
    
    response = chat(
        model="llama3.1:8b",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": "Call the tool now."},
        ],
        options={"temperature": 0.3},
    )
    
    # 解析 AI 的回答（應該是 JSON）
    try:
        # 清理 AI 回答中可能有的多餘文字
        raw_text = response.message.content
        # 嘗試找出 JSON 部分
        json_match = re.search(r"\{.*\}", raw_text, re.DOTALL)
        if json_match:
            tool_call = json.loads(json_match.group())
        else:
            tool_call = json.loads(raw_text)
            
        print(f"AI 產生的工具呼叫: {tool_call}")
        
        # 執行工具
        tool_name = tool_call["tool"]
        tool_args = tool_call.get("args", {})
        result = TOOL_REGISTRY[tool_name](**tool_args)
        
        print(f"工具執行結果: {result}")
        print("✅ SUCCESS")
        return True
        
    except Exception as e:
        print(f"❌ 錯誤: {e}")
        return False


if __name__ == "__main__":
    test_your_prompt(YOUR_SYSTEM_PROMPT)
```

### 📝 工具呼叫的實際應用

```
場景 1：程式碼修復（像 GitHub Copilot）
  AI：我發現了一個 bug，讓我執行測試確認...
  工具呼叫：{"tool": "pytest", "args": {"path": "tests/"}}
  結果：3 passed, 1 failed
  AI：test_empty_list 失敗了，讓我修復...

場景 2：網頁搜尋
  AI：讓我查一下這個 API 的文件...
  工具呼叫：{"tool": "web_search", "args": {"query": "Python requests library"}}
  結果：[搜尋結果...]
  AI：根據文件，您應該這樣使用...

場景 3：檔案操作
  AI：讓我讀取設定檔...
  工具呼叫：{"tool": "read_file", "args": {"path": "config.json"}}
  結果：{"database": "mysql", ...}
  AI：我看到您使用的是 MySQL 資料庫...
```

### ▶️ 執行指令

```bash
cd week1
python3 tool_calling.py
```

---

## 技巧 4️⃣：自洽性提示（陪審團投票）

### 📁 檔案位置
```
week1/self_consistency_prompting.py
```

### 🎯 這個練習在做什麼？

**任務：** 解一個數學文字題

```
題目（翻譯）：
Henry 騎自行車行程 60 英里。
他第一次停在 20 英里處。
他第二次停在終點前 15 英里處。
問：兩次停留之間他騎了多少英里？

畫圖理解：
起點 -------- 第一次停 -------- 第二次停 -------- 終點
0 英里        20 英里           45 英里          60 英里
              |<--- 25 英里 --->|
              
計算：
第二次停的位置 = 60 - 15 = 45 英里
兩次停之間的距離 = 45 - 20 = 25 英里

答案：25 英里
```

### 🗳️ 什麼是「自洽性提示」？

**像陪審團投票：問多次，取多數答案**

```
為什麼要這樣做？

AI 不是 100% 可靠：
  第 1 次問 → 答案 25 ✓
  第 2 次問 → 答案 25 ✓
  第 3 次問 → 答案 35 ✗（算錯了）
  第 4 次問 → 答案 25 ✓
  第 5 次問 → 答案 25 ✓

投票結果：
  25 得 4 票
  35 得 1 票

最終答案：25 ✓
```

### 🌡️ 為什麼用高溫度（temperature=1）？

```
溫度（Temperature）是控制 AI 「隨機性」的參數：

低溫度（0.1-0.3）：
  - AI 每次回答幾乎相同
  - 適合需要穩定結果的情況
  
高溫度（0.7-1.0）：
  - AI 每次回答會有變化
  - 適合創意寫作或「自洽性」投票

為什麼自洽性需要高溫度？
  - 如果每次回答都一樣，投票就沒意義了！
  - 高溫度讓 AI 探索不同的解題思路
  - 多數正確的思路會「勝出」
```

### 💻 完整程式碼解析

```python
import re
from collections import Counter  # Counter 是用來計票的工具
from ollama import chat

NUM_RUNS_TIMES = 5  # 問 5 次

# ═══════════════════════════════════════════════════════════
# 🎯 這是您需要修改的部分！
# ═══════════════════════════════════════════════════════════
YOUR_SYSTEM_PROMPT = """
你是一位數學老師。解決問題時：

1. 仔細閱讀題目
2. 畫出示意圖或列出已知條件
3. 逐步計算
4. 檢查答案是否合理
5. 最後一行寫 "Answer: <數字>"
"""

USER_PROMPT = """
Solve this problem, then give the final answer on the last line as "Answer: <number>".

Henry made two stops during his 60-mile bike trip. He first stopped after 20
miles. His second stop was 15 miles before the end of the trip. How many miles
did he travel between his first and second stops?
"""

EXPECTED_OUTPUT = "Answer: 25"


def extract_final_answer(text: str) -> str:
    """從 AI 回答中提取 Answer: xxx"""
    matches = re.findall(r"(?mi)^\s*answer\s*:\s*(.+)\s*$", text)
    if matches:
        value = matches[-1].strip()
        num_match = re.search(r"-?\d+(?:\.\d+)?", value.replace(",", ""))
        if num_match:
            return f"Answer: {num_match.group(0)}"
        return f"Answer: {value}"
    return text.strip()


def test_your_prompt(system_prompt: str) -> bool:
    """執行 5 次，用多數投票決定答案"""
    
    answers = []  # 收集所有答案
    
    for idx in range(NUM_RUNS_TIMES):
        print(f"第 {idx + 1} 次詢問")
        
        response = chat(
            model="llama3.1:8b",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": USER_PROMPT},
            ],
            options={"temperature": 1},  # 🌡️ 高溫度 = 更多變化
        )
        
        # 提取答案
        answer = extract_final_answer(response.message.content)
        print(f"  答案: {answer}")
        answers.append(answer)
    
    # 🗳️ 投票統計
    # Counter 會計算每個答案出現幾次
    # 例如：Counter(["A", "A", "B"]) = {"A": 2, "B": 1}
    counts = Counter(answers)
    
    # most_common(1) 回傳出現最多次的項目
    # 回傳格式：[("Answer: 25", 4)]
    majority_answer, majority_count = counts.most_common(1)[0]
    
    print(f"\n投票結果:")
    for ans, count in counts.most_common():
        print(f"  {ans}: {count} 票")
    
    print(f"\n多數答案: {majority_answer} ({majority_count}/{NUM_RUNS_TIMES})")
    
    if majority_answer.strip() == EXPECTED_OUTPUT.strip():
        print("✅ SUCCESS")
        return True
    else:
        print(f"❌ 期望: {EXPECTED_OUTPUT}")
        return False


if __name__ == "__main__":
    test_your_prompt(YOUR_SYSTEM_PROMPT)
```

### 📊 預期輸出

```
第 1 次詢問
  答案: Answer: 25
第 2 次詢問
  答案: Answer: 25
第 3 次詢問
  答案: Answer: 35
第 4 次詢問
  答案: Answer: 25
第 5 次詢問
  答案: Answer: 25

投票結果:
  Answer: 25: 4 票
  Answer: 35: 1 票

多數答案: Answer: 25 (4/5)
✅ SUCCESS
```

### ▶️ 執行指令

```bash
cd week1
python3 self_consistency_prompting.py
```

---

## 技巧 5️⃣：RAG（檢索增強生成）

### 📁 檔案位置
```
week1/rag.py
week1/data/api_docs.txt
```

### 🎯 這個練習在做什麼？

**任務：** 根據 API 文件，寫一個 Python 函式

### 📖 什麼是 RAG？

**RAG = Retrieval Augmented Generation = 檢索增強生成**

**白話文：給 AI 參考資料，讓它不要亂編**

```
❌ 沒有 RAG（AI 可能編造）：
問：寫一個函式呼叫 API 獲取使用者名稱
答：
    def get_user(id):
        # ⚠️ 這個 URL 是編造的！
        response = requests.get("https://some-api.com/user/" + id)
        # ⚠️ 這個欄位名也是猜的！
        return response.json()["username"]

✅ 有 RAG（給 AI 真實文件）：
參考文件：
    Base URL: https://api.example.com/v1
    認證: Header X-API-Key
    端點: GET /users/{id}
    回傳: {"id": "...", "name": "..."}

問：根據上面的文件，寫一個函式
答：
    def fetch_user_name(user_id, api_key):
        response = requests.get(
            f"https://api.example.com/v1/users/{user_id}",  # ← 來自文件！
            headers={"X-API-Key": api_key}                  # ← 來自文件！
        )
        return response.json()["name"]                      # ← 來自文件！
```

### 📄 API 文件內容

檔案 `data/api_docs.txt`：

```
API Reference

Base URL: https://api.example.com/v1

Authentication:
  Provide header X-API-Key: <your key>

Endpoints:
  GET /users/{id}
    - Returns 200 with JSON: {"id": <string>, "name": <string>}
```

### 🔐 什麼是認證（Authentication）？

```
當您使用 API 時，伺服器需要知道「您是誰」

常見的認證方式：
1. API Key（本題使用）
   - 像一把「鑰匙」
   - 放在 HTTP 請求的 header 中
   - 例如：X-API-Key: abc123xyz

2. OAuth Token（進階）
   - 像 Google 登入
   - 使用者授權後獲得的令牌

3. Basic Auth
   - 使用者名稱 + 密碼
```

### 💻 您需要修改兩個地方

```python
from typing import List
from ollama import chat

# 載入語料庫（就是 API 文件）
CORPUS_PATH = "data/api_docs.txt"
with open(CORPUS_PATH, "r") as f:
    CORPUS = [f.read()]  # CORPUS[0] 就是文件內容

# ═══════════════════════════════════════════════════════════
# 🎯 修改 1：系統提示
# ═══════════════════════════════════════════════════════════
YOUR_SYSTEM_PROMPT = """
你是一位 Python 開發者。根據提供的 API 文件撰寫程式碼。

你會收到一份 API 參考文件，請根據文件內容：
1. 使用正確的 Base URL
2. 使用正確的認證方式（X-API-Key header）
3. 使用正確的端點路徑
4. 使用正確的回傳欄位名稱

只輸出程式碼，不要解釋。
"""

# ═══════════════════════════════════════════════════════════
# 🎯 修改 2：上下文提供函式
# ═══════════════════════════════════════════════════════════
def YOUR_CONTEXT_PROVIDER(corpus: List[str]) -> List[str]:
    """
    從語料庫中選擇相關文件
    
    corpus 是一個列表，corpus[0] 就是 api_docs.txt 的內容
    
    在真實的 RAG 系統中，這個函式會：
    1. 接收使用者的問題
    2. 用向量搜尋找到最相關的文件片段
    3. 返回這些片段
    
    但這個練習中，我們只有一份文件，所以直接返回它
    """
    return [corpus[0]]


# ═══════════════════════════════════════════════════════════
# 測試函式
# ═══════════════════════════════════════════════════════════
def test_your_prompt(system_prompt: str, context_provider) -> bool:
    # 獲取相關文件
    context_docs = context_provider(CORPUS)
    
    # 構建完整的提示
    # 將文件內容嵌入到使用者訊息中
    user_message = f"""
Here is some relevant documentation:

{context_docs[0]}

---

Based on the documentation above, write a Python function called `fetch_user_name`
that takes a user_id and api_key as parameters and returns the user's name.
"""
    
    response = chat(
        model="llama3.1:8b",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message},
        ],
        options={"temperature": 0.3},
    )
    
    code = response.message.content
    
    # 檢查生成的程式碼是否包含必要元素
    required_elements = [
        "def fetch_user_name",   # 函式定義
        "requests.get",          # 使用 requests 函式庫
        "/users/",               # 正確的端點
        "X-API-Key",             # 認證標頭
        "return",                # 有回傳值
    ]
    
    for element in required_elements:
        if element not in code:
            print(f"❌ 缺少: {element}")
            return False
    
    print("✅ SUCCESS - 程式碼包含所有必要元素")
    return True
```

### ▶️ 執行指令

```bash
cd week1
python3 rag.py
```

---

## 技巧 6️⃣：反思（Reflexion）

### 📁 檔案位置
```
week1/reflexion.py
```

### 🎯 這個練習在做什麼？

**任務：** 讓 AI 寫一個密碼驗證函式，並透過測試反饋來改進

### 🔐 密碼驗證規則

```
有效的密碼必須包含：
✅ 至少一個大寫字母 (A-Z)
✅ 至少一個數字 (0-9)
✅ 至少一個特殊字元 (!@#$%^&*()-_)

測試案例：
"Password1!"  → True  （有大寫 P，有數字 1，有特殊字元 !）
"password1!" → False （沒有大寫）
"Password!"  → False （沒有數字）
"Password1"  → False （沒有特殊字元）
```

### 🔄 什麼是「反思」？

**反思 = 讓 AI 看到錯誤，然後修正**

```
第一輪：
AI 寫的程式碼：
    def is_valid_password(password):
        return len(password) >= 8  # AI 猜測「長度夠就行」

執行測試...
測試結果：
    ❌ "Password1!" 應該是 True，但得到 False
    ❌ "password1!" 應該是 False，但得到 True
    ...

第二輪（反思）：
系統告訴 AI：
    「你的程式碼有問題，以下測試失敗了：...」

AI 看了錯誤後修正：
    def is_valid_password(password):
        has_upper = any(c.isupper() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(c in "!@#$%^&*()-_" for c in password)
        return has_upper and has_digit and has_special

執行測試...
✅ 全部通過！
```

### ⚠️ 什麼是 IndexError？

```python
# IndexError 是 Python 的錯誤，表示「索引超出範圍」

my_list = ["a", "b", "c"]
#          [0]  [1]  [2]

print(my_list[0])  # ✅ 印出 "a"
print(my_list[2])  # ✅ 印出 "c"
print(my_list[3])  # ❌ IndexError! 沒有索引 3

# 在 reflexion.py 中，如果 AI 沒有生成任何程式碼
# 嘗試存取空列表的 [0] 就會發生 IndexError
```

### 💻 您需要修改兩個地方

```python
from typing import List
from ollama import chat
import re

NUM_ITERATIONS = 3  # 最多反思 3 次

# 測試案例
TEST_CASES = [
    ("Password1!", True),   # 有大寫、數字、特殊字元
    ("password1!", False),  # 沒有大寫
    ("Password!", False),   # 沒有數字
    ("Password1", False),   # 沒有特殊字元
    ("P1!", True),          # 都有，雖然很短
    ("", False),            # 空字串
]

# ═══════════════════════════════════════════════════════════
# 🎯 修改 1：反思提示
# ═══════════════════════════════════════════════════════════
YOUR_REFLEXION_PROMPT = """
你是一位程式碼修復專家。

你會收到：
1. 原本的程式碼
2. 失敗的測試案例

請分析失敗原因，然後輸出修正後的完整程式碼。

密碼驗證規則：
- 至少一個大寫字母 (A-Z)
- 至少一個數字 (0-9)
- 至少一個特殊字元 (!@#$%^&*()-_)

只輸出 Python 程式碼，不要解釋。
"""

# ═══════════════════════════════════════════════════════════
# 🎯 修改 2：建構反思上下文
# ═══════════════════════════════════════════════════════════
def your_build_reflexion_context(prev_code: str, failures: List[str]) -> str:
    """
    建構要給 AI 的反思資訊
    
    prev_code: 原本的程式碼
    failures: 失敗的測試案例列表，格式如：
              ["is_valid_password('abc') 應該是 False，但得到 True"]
    
    返回：完整的反思上下文字串
    """
    # chr(10) 是換行符號 '\n'，用在 f-string 中
    failure_list = chr(10).join('- ' + f for f in failures)
    
    return f"""
原本的程式碼：
```python
{prev_code}
```

失敗的測試：
{failure_list}

請修正程式碼以通過所有測試。
"""


# ═══════════════════════════════════════════════════════════
# 執行測試的函式
# ═══════════════════════════════════════════════════════════
def run_tests(code: str) -> List[str]:
    """
    執行測試案例，返回失敗的列表
    """
    failures = []
    
    # 動態執行 AI 生成的程式碼
    try:
        exec(code, globals())  # 這會在全域命名空間中定義函式
    except Exception as e:
        return [f"程式碼執行錯誤: {e}"]
    
    for password, expected in TEST_CASES:
        try:
            result = is_valid_password(password)
            if result != expected:
                failures.append(
                    f"is_valid_password('{password}') 應該是 {expected}，但得到 {result}"
                )
        except Exception as e:
            failures.append(f"is_valid_password('{password}') 發生錯誤: {e}")
    
    return failures
```

### 📊 預期流程

```
=== 第一輪 ===
AI 生成初始程式碼...
初始程式碼:
def is_valid_password(password):
    return True

執行測試...
❌ 失敗: is_valid_password('password1!') 應該是 False，得到 True
❌ 失敗: is_valid_password('Password!') 應該是 False，得到 True
❌ 失敗: is_valid_password('Password1') 應該是 False，得到 True
❌ 失敗: is_valid_password('') 應該是 False，得到 True

=== 第二輪（反思） ===
將失敗資訊告訴 AI...
AI 修正程式碼...

修正後程式碼:
def is_valid_password(password):
    has_upper = any(c.isupper() for c in password)
    has_digit = any(c.isdigit() for c in password)
    has_special = any(c in "!@#$%^&*()-_" for c in password)
    return has_upper and has_digit and has_special

執行測試...
✅ SUCCESS - 所有測試通過！
```

### ▶️ 執行指令

```bash
cd week1
python3 reflexion.py
```

---

# 📋 第四章：完整作業清單

## ✅ 進度追蹤

| # | 技巧 | 檔案 | 狀態 |
|---|------|------|------|
| 1 | 思考鏈 | `chain_of_thought.py` | ⬜ |
| 2 | Few-shot | `k_shot_prompting.py` | ⬜ |
| 3 | 工具呼叫 | `tool_calling.py` | ⬜ |
| 4 | 自洽性 | `self_consistency_prompting.py` | ⬜ |
| 5 | RAG | `rag.py` | ⬜ |
| 6 | 反思 | `reflexion.py` | ⬜ |

**每個作業 10 分，共 60 分**

---

# 🐛 第五章：常見問題解答

## Q1：「Connection refused」錯誤

```
錯誤訊息：
ConnectionRefusedError: [Errno 111] Connection refused
```

**原因：** Ollama 服務沒有啟動

**解決：**
```bash
# 開啟新終端，執行：
ollama serve
```

## Q2：「Model not found」錯誤

```
錯誤訊息：
Error: model "llama3.1:8b" not found
```

**原因：** 模型沒有下載

**解決：**
```bash
ollama pull llama3.1:8b
ollama pull mistral-nemo:12b
```

## Q3：「No module named 'ollama'」錯誤

**原因：** Python 套件沒有安裝

**解決：**
```bash
pip3 install ollama python-dotenv
```

## Q4：程式一直失敗，怎麼改進提示？

**技巧 1：加入角色設定**
```
❌ 壞："計算 3^12345 mod 100"
✅ 好："你是一位數學專家，擅長數論和模運算..."
```

**技巧 2：要求展示步驟**
```
❌ 壞："給我答案"
✅ 好："請逐步思考，展示每一步計算過程"
```

**技巧 3：指定輸出格式**
```
❌ 壞："告訴我結果"
✅ 好："最後一行必須是 'Answer: <數字>'"
```

## Q5：程式碼執行太慢

**原因：** 本地 AI 模型需要較多計算資源

**解決：**
- 第一次執行會比較慢（模型載入）
- 之後會快一些
- 如果電腦太舊，可能需要 1-2 分鐘

## Q6：什麼是 CI（持續整合）？

```
CI = Continuous Integration = 持續整合

這是一種自動化流程：
1. 您把程式碼推送到 GitHub
2. GitHub 自動執行測試
3. 如果測試失敗，您會收到通知

Week 1 的作業會透過 CI 自動評分
```

---

# 📖 第六章：術語總整理

| 術語 | 英文 | 說明 |
|------|------|------|
| 提示 | Prompt | 給 AI 的指令或問題 |
| 系統提示 | System Prompt | 設定 AI 的「角色」或「行為規則」 |
| 溫度 | Temperature | 控制 AI 回答的隨機程度（0-2） |
| 思考鏈 | Chain of Thought (CoT) | 讓 AI 展示推理步驟 |
| Few-shot | Few-shot | 給 AI 範例學習 |
| 工具呼叫 | Tool Calling | 讓 AI 使用外部工具 |
| 自洽性 | Self-Consistency | 多次詢問，取多數答案 |
| RAG | Retrieval Augmented Generation | 給 AI 參考文件 |
| 反思 | Reflexion | 讓 AI 根據錯誤修正答案 |
| 幻覺 | Hallucination | AI 編造不存在的資訊 |
| 令牌 | Token | AI 處理文字的基本單位 |
| 推論 | Inference | AI 根據輸入產生輸出的過程 |

---

# 🎉 第七章：完成後的下一步

## 您已經學會了：

1. ✅ 如何讓 AI 展示推理過程（思考鏈）
2. ✅ 如何用範例教 AI（Few-shot）
3. ✅ 如何讓 AI 使用外部工具（工具呼叫）
4. ✅ 如何用多數投票提高準確性（自洽性）
5. ✅ 如何給 AI 參考資料（RAG）
6. ✅ 如何讓 AI 從錯誤中學習（反思）

## 推薦資源：

- **Anthropic 提示工程指南：** https://docs.anthropic.com/
- **Ollama 官方文件：** https://ollama.com/
- **課程網站：** https://themodernsoftware.dev

---

**最後更新：** 2025 年 12 月 7 日  
**基於：** Stanford CS146S - The Modern Software Developer (Fall 2025)  
**授課教授：** Mihail Eric
