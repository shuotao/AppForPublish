from pathlib import Path
from typing import Any, Dict, List
from fastmcp import FastMCP

# TODO: 建立 MCP 伺服器實例
# 提示：使用 FastMCP 並給它一個描述性的名稱
mcp = FastMCP(name="SimpleMCPPracticeServer")

def resolve_abs_path(path_str: str) -> Path:
    """
    將相對路徑或 ~ 路徑轉換為絕對路徑
    例如: file.py -> /Users/home/user/file.py
    """
    path = Path(path_str).expanduser()
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    return path

# TODO: 實作 read_file_tool 並加上 @mcp.tool 裝飾器
# 提示：
# 1. 使用 @mcp.tool 裝飾器讓這個函式成為 MCP 工具
# 2. 撰寫清晰的 docstring（MCP 會使用它作為工具描述）
# 3. 使用型別提示（type hints）
@mcp.tool
def read_file_tool(filename: str) -> Dict[str, Any]:
    """
    讀取使用者指定的檔案完整內容。
    :param filename: 要讀取的檔案名稱
    :return: 包含檔案路徑和內容的字典
    """
    full_path = resolve_abs_path(filename)
    print(f"讀取檔案: {full_path}")
    
    # TODO: 實作檔案讀取邏輯
    # 提示：記得處理可能的錯誤（檔案不存在等）
    pass

# TODO: 實作 list_files_tool 並加上 @mcp.tool 裝飾器
@mcp.tool
def list_files_tool(path: str) -> Dict[str, Any]:
    """
    列出使用者指定目錄中的檔案。
    :param path: 要列出檔案的目錄路徑
    :return: 包含路徑和檔案列表的字典
    """
    full_path = resolve_abs_path(path)
    all_files = []
    
    # TODO: 實作目錄列表邏輯
    pass

# TODO: 實作 edit_file_tool 並加上 @mcp.tool 裝飾器
@mcp.tool
def edit_file_tool(path: str, old_str: str, new_str: str) -> Dict[str, Any]:
    """
    替換檔案中第一次出現的 old_str 為 new_str。
    如果 old_str 為空字串，則建立/覆寫檔案為 new_str 的內容。
    :param path: 要編輯的檔案路徑
    :param old_str: 要替換的字串
    :param new_str: 替換後的字串
    :return: 包含路徑和執行動作的字典
    """
    full_path = resolve_abs_path(path)
    p = Path(full_path)
    
    # TODO: 實作檔案編輯邏輯
    # 提示：
    # 1. 如果 old_str 為空，建立新檔案
    # 2. 否則讀取並替換內容
    # 3. 處理 old_str 找不到的情況
    pass

# TODO: 啟動 MCP 伺服器
# 提示：在 __main__ 區塊中呼叫 mcp.run()
if __name__ == "__main__":
    # TODO: 執行 MCP 伺服器
    # 提示：使用 mcp.run() 啟動伺服器
    # 伺服器會監聽標準輸入/輸出（stdio 模式）
    pass
