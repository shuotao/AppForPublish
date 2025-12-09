#!/bin/bash

# ═══════════════════════════════════════════════════════════
# Week 2 課程資料同步腳本
# 用途：從 modern-software-dev-assignments/week2/ 同步最新檔案
# 使用：拖曳這個檔案到終端視窗，或執行 ./sync_from_official.sh
# ═══════════════════════════════════════════════════════════

# 取得腳本所在目錄（就是 week2/）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 官方課程資料夾路徑
OFFICIAL_DIR="$SCRIPT_DIR/../modern-software-dev-assignments/week2"

echo "🔄 Week 2 課程資料同步工具"
echo "================================"
echo ""
echo "📂 工作資料夾: $SCRIPT_DIR"
echo "📚 官方資料夾: $OFFICIAL_DIR"
echo ""

# 檢查官方資料夾是否存在
if [ ! -d "$OFFICIAL_DIR" ]; then
    echo "❌ 錯誤：找不到官方資料夾"
    echo "   請確認 modern-software-dev-assignments 資料夾存在"
    exit 1
fi

# 詢問是否先更新官方資料
echo "是否先從 GitHub 更新官方課程資料？(y/n)"
read -r update_official

if [ "$update_official" = "y" ] || [ "$update_official" = "Y" ]; then
    echo ""
    echo "📥 更新官方課程資料..."
    cd "$OFFICIAL_DIR/.." || exit
    git pull origin main
    cd "$SCRIPT_DIR" || exit
    echo "✅ 官方資料已更新"
    echo ""
fi

# 要同步的檔案列表（參考用）
# Week 2 主要是 FastAPI 專案，結構較複雜
echo "📋 可同步的檔案："
echo "   - assignment.md (作業說明)"
echo "   - writeup.md (撰寫範本)"
echo "   - app/ (FastAPI 應用程式)"
echo "   - frontend/ (前端頁面)"
echo "   - tests/ (測試檔案)"
echo ""

# 詢問要同步哪些檔案
echo "選擇同步選項："
echo "1) 只同步文件（assignment.md, writeup.md）"
echo "2) 同步所有檔案（會覆蓋現有檔案）"
echo "3) 取消"
echo ""
read -r -p "請選擇 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📄 同步文件..."
        
        # 備份現有檔案
        if [ -f "$SCRIPT_DIR/assignment.md" ]; then
            cp "$SCRIPT_DIR/assignment.md" "$SCRIPT_DIR/assignment.md.backup.$(date +%Y%m%d_%H%M%S)"
            echo "✅ 已備份 assignment.md"
        fi
        
        # 複製文件
        cp "$OFFICIAL_DIR/assignment.md" "$SCRIPT_DIR/" 2>/dev/null && echo "✅ 已同步 assignment.md" || echo "⚠️  assignment.md 同步失敗"
        cp "$OFFICIAL_DIR/writeup.md" "$SCRIPT_DIR/" 2>/dev/null && echo "✅ 已同步 writeup.md" || echo "⚠️  writeup.md 同步失敗"
        
        echo ""
        echo "✅ 文件同步完成"
        ;;
    
    2)
        echo ""
        echo "⚠️  警告：這會覆蓋所有現有檔案！"
        echo "確定要繼續嗎？(yes/no)"
        read -r confirm
        
        if [ "$confirm" = "yes" ]; then
            echo ""
            echo "📦 同步所有檔案..."
            
            # 建立備份
            BACKUP_DIR="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            echo "📂 建立備份於: $BACKUP_DIR"
            
            # 備份現有檔案
            [ -d "$SCRIPT_DIR/app" ] && cp -r "$SCRIPT_DIR/app" "$BACKUP_DIR/"
            [ -d "$SCRIPT_DIR/frontend" ] && cp -r "$SCRIPT_DIR/frontend" "$BACKUP_DIR/"
            [ -d "$SCRIPT_DIR/tests" ] && cp -r "$SCRIPT_DIR/tests" "$BACKUP_DIR/"
            [ -f "$SCRIPT_DIR/assignment.md" ] && cp "$SCRIPT_DIR/assignment.md" "$BACKUP_DIR/"
            [ -f "$SCRIPT_DIR/writeup.md" ] && cp "$SCRIPT_DIR/writeup.md" "$BACKUP_DIR/"
            
            # 同步檔案
            echo ""
            echo "複製檔案中..."
            rsync -av --exclude='__pycache__' --exclude='*.pyc' \
                "$OFFICIAL_DIR/" "$SCRIPT_DIR/" \
                --exclude='data/' \
                --exclude='coding_agent_from_scratch_lecture.py' \
                --exclude='simple_mcp.py' \
                --exclude='*.pdf' \
                --exclude='README.md' \
                --exclude='DATA_PREPARATION.md' \
                --exclude='VERIFICATION.txt'
            
            echo ""
            echo "✅ 所有檔案同步完成"
            echo "📦 備份位置: $BACKUP_DIR"
        else
            echo "❌ 已取消同步"
        fi
        ;;
    
    3)
        echo "❌ 已取消同步"
        exit 0
        ;;
    
    *)
        echo "❌ 無效的選擇"
        exit 1
        ;;
esac

echo ""
echo "================================"
echo "🎉 同步完成！"
echo ""
echo "💡 提示："
echo "   - 備份檔案會保存在 backup_* 資料夾中"
echo "   - 可以使用 git diff 查看變更"
echo "   - 記得更新你的程式碼以符合新的作業要求"
echo ""
