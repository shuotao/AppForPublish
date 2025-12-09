import inspect
import json
import os

from openai import OpenAI
from dotenv import load_dotenv
from pathlib import Path
from typing import Any, Dict, List, Tuple

load_dotenv()

# TODO: 設定你的 OpenAI API Key
openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

# TODO: 完成系統提示詞
# 提示：系統提示詞應該要告訴 LLM：
# 1. 它的角色是什麼（編碼助手）
# 2. 有哪些工具可以使用
# 3. 如何呼叫工具（格式：tool: TOOL_NAME({"param": "value"})）
# 4. 收到 tool_result 後如何繼續
SYSTEM_PROMPT = """
你是一個編碼助手，目標是協助我們解決編碼任務。
你可以使用以下工具：

{tool_list_repr}

當你想使用工具時，請以以下格式回覆（只回覆這一行，其他什麼都不要說）：
tool: TOOL_NAME({{"參數名": "參數值"}})

使用緊湊的單行 JSON 格式，並使用雙引號。
收到 tool_result(...) 訊息後，請繼續任務。
如果不需要使用工具，請正常回應。
"""

YOU_COLOR = "\u001b[94m"
ASSISTANT_COLOR = "\u001b[93m"
RESET_COLOR = "\u001b[0m"

def resolve_abs_path(path_str: str) -> Path:
    """
    將相對路徑或 ~ 路徑轉換為絕對路徑
    例如: file.py -> /Users/home/user/file.py
    """
    path = Path(path_str).expanduser()
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    return path

# TODO: 實作 read_file_tool
# 這個工具應該要能夠讀取檔案的完整內容
def read_file_tool(filename: str) -> Dict[str, Any]:
    """
    讀取使用者指定的檔案內容。
    :param filename: 要讀取的檔案名稱
    :return: 包含檔案路徑和內容的字典
    """
    # 提示：
    # 1. 使用 resolve_abs_path 取得完整路徑
    # 2. 使用 open() 讀取檔案內容
    # 3. 回傳格式：{"file_path": "...", "content": "..."}
    full_path = resolve_abs_path(filename)
    print(f"讀取檔案: {full_path}")
    
    # TODO: 在這裡實作檔案讀取邏輯
    pass

# TODO: 實作 list_files_tool
# 這個工具應該要能夠列出目錄中的所有檔案和子目錄
def list_files_tool(path: str) -> Dict[str, Any]:
    """
    列出使用者指定目錄中的檔案。
    :param path: 要列出檔案的目錄路徑
    :return: 包含路徑和檔案列表的字典
    """
    # 提示：
    # 1. 使用 resolve_abs_path 取得完整路徑
    # 2. 使用 Path.iterdir() 遍歷目錄
    # 3. 區分檔案和目錄（使用 is_file() 和 is_dir()）
    # 4. 回傳格式：{"path": "...", "files": [{"filename": "...", "type": "file/dir"}, ...]}
    full_path = resolve_abs_path(path)
    all_files = []
    
    # TODO: 在這裡實作目錄列表邏輯
    pass

# TODO: 實作 edit_file_tool
# 這個工具應該要能夠編輯或建立檔案
def edit_file_tool(path: str, old_str: str, new_str: str) -> Dict[str, Any]:
    """
    替換檔案中第一次出現的 old_str 為 new_str。
    如果 old_str 為空字串，則建立/覆寫檔案為 new_str 的內容。
    :param path: 要編輯的檔案路徑
    :param old_str: 要替換的字串
    :param new_str: 替換後的字串
    :return: 包含路徑和執行動作的字典
    """
    # 提示：
    # 1. 使用 resolve_abs_path 取得完整路徑
    # 2. 如果 old_str 為空，直接寫入 new_str 並回傳 {"action": "created_file"}
    # 3. 否則讀取檔案內容，使用 replace() 替換第一次出現的 old_str
    # 4. 如果找不到 old_str，回傳 {"action": "old_str not found"}
    # 5. 成功編輯後回傳 {"action": "edited"}
    full_path = resolve_abs_path(path)
    
    # TODO: 在這裡實作檔案編輯邏輯
    pass

# 工具註冊表：將工具名稱對應到函式
TOOL_REGISTRY = {
    "read_file": read_file_tool,
    "list_files": list_files_tool,
    "edit_file": edit_file_tool 
}

def get_tool_str_representation(tool_name: str) -> str:
    """
    取得工具的字串表示（名稱、描述、參數）
    """
    tool = TOOL_REGISTRY[tool_name]
    return f"""
    Name: {tool_name}
    Description: {tool.__doc__}
    Signature: {inspect.signature(tool)}
    """

def get_full_system_prompt():
    """
    產生完整的系統提示詞，包含所有工具的描述
    """
    tool_str_repr = ""
    for tool_name in TOOL_REGISTRY:
        tool_str_repr += "TOOL\n===" + get_tool_str_representation(tool_name)
        tool_str_repr += f"\n{"="*15}\n"
    return SYSTEM_PROMPT.format(tool_list_repr=tool_str_repr)

# TODO: 實作 extract_tool_invocations
# 這個函式需要從 LLM 的回應中解析出工具呼叫
def extract_tool_invocations(text: str) -> List[Tuple[str, Dict[str, Any]]]:
    """
    從文字中提取 'tool: name({...})' 格式的工具呼叫。
    解析器預期單行、緊湊的 JSON 格式在括號中。
    :return: (tool_name, args) 的列表
    """
    # 提示：
    # 1. 按行分割文字
    # 2. 檢查每行是否以 "tool:" 開頭
    # 3. 解析格式：tool: TOOL_NAME({"param": "value"})
    # 4. 提取工具名稱和 JSON 參數
    # 5. 使用 json.loads() 解析 JSON
    invocations = []
    
    # TODO: 在這裡實作工具呼叫解析邏輯
    # 範例回傳：[("read_file", {"filename": "test.txt"})]
    
    return invocations

def execute_llm_call(conversation: List[Dict[str, str]]):
    """
    呼叫 OpenAI API 並取得回應
    """
    response = openai_client.chat.completions.create(
        model="gpt-4o-mini",  # 使用較小的模型以節省成本
        messages=conversation,
        max_completion_tokens=2000
    )
    return response.choices[0].message.content

# TODO: 實作主要的代理迴圈
def run_coding_agent_loop():
    """
    執行編碼代理的主迴圈：
    1. 接收使用者輸入
    2. 呼叫 LLM
    3. 檢查是否有工具呼叫
    4. 執行工具並將結果回傳給 LLM
    5. 重複直到 LLM 給出最終回應
    """
    print("="*50)
    print("編碼代理啟動！")
    print("系統提示詞：")
    print(get_full_system_prompt())
    print("="*50)
    
    # 初始化對話歷史，包含系統提示詞
    conversation = [{
        "role": "system",
        "content": get_full_system_prompt()
    }]
    
    while True:
        try:
            # 取得使用者輸入
            user_input = input(f"{YOU_COLOR}You:{RESET_COLOR} ")
        except (KeyboardInterrupt, EOFError):
            print("\n再見！")
            break
        
        # 將使用者訊息加入對話
        conversation.append({
            "role": "user",
            "content": user_input.strip()
        })
        
        # TODO: 實作工具呼叫迴圈
        # 提示：
        # 1. 呼叫 execute_llm_call 取得 LLM 回應
        # 2. 使用 extract_tool_invocations 檢查是否有工具呼叫
        # 3. 如果沒有工具呼叫，顯示回應並結束這輪迴圈
        # 4. 如果有工具呼叫：
        #    a. 執行每個工具
        #    b. 將 tool_result(...) 加入對話
        #    c. 繼續迴圈直到沒有工具呼叫
        
        while True:
            # TODO: 呼叫 LLM
            assistant_response = execute_llm_call(conversation)
            
            # TODO: 檢查是否有工具呼叫
            tool_invocations = extract_tool_invocations(assistant_response)
            
            if not tool_invocations:
                # 沒有工具呼叫，顯示最終回應
                print(f"{ASSISTANT_COLOR}Assistant:{RESET_COLOR} {assistant_response}")
                conversation.append({
                    "role": "assistant",
                    "content": assistant_response
                })
                break
            
            # TODO: 執行工具並回傳結果
            for name, args in tool_invocations:
                tool = TOOL_REGISTRY[name]
                print(f"\n[執行工具: {name}]")
                print(f"[參數: {args}]")
                
                # 根據不同的工具呼叫對應的函式
                # 提示：不同工具有不同的參數，需要正確傳遞
                resp = ""
                # TODO: 在這裡實作工具執行邏輯
                
                # 將工具結果加入對話
                conversation.append({
                    "role": "user",
                    "content": f"tool_result({json.dumps(resp)})"
                })

if __name__ == "__main__":
    run_coding_agent_loop()
