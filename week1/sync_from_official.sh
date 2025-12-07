#!/bin/bash

# ═══════════════════════════════════════════════════════════
# Week 1 課程資料同步腳本
# 用途：從 modern-software-dev-assignments/week1/ 同步最新檔案
# 使用：拖曳這個檔案到終端視窗，或執行 ./sync_from_official.sh
# ═══════════════════════════════════════════════════════════

# 取得腳本所在目錄（就是 week1/）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 官方課程資料夾路徑
OFFICIAL_DIR="$SCRIPT_DIR/../modern-software-dev-assignments/week1"

echo "🔄 Week 1 課程資料同步工具"
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

# 要同步的檔案列表
FILES=(
    "chain_of_thought.py"
    "k_shot_prompting.py"
    "tool_calling.py"
    "self_consistency_prompting.py"
    "rag.py"
    "reflexion.py"
    "assignment.md"
    "README.md"
)

# 計數器
updated_count=0
skipped_count=0
unchanged_count=0

echo "🔍 檢查檔案差異..."
echo "================================"
echo ""

# 逐一檢查每個檔案
for file in "${FILES[@]}"; do
    official_file="$OFFICIAL_DIR/$file"
    local_file="$SCRIPT_DIR/$file"
    
    # 檢查官方檔案是否存在
    if [ ! -f "$official_file" ]; then
        echo "⚠️  $file - 官方檔案不存在，跳過"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # 檢查本地檔案是否存在
    if [ ! -f "$local_file" ]; then
        echo "🆕 $file - 本地沒有此檔案"
        echo "   是否從官方複製？(y/n)"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            cp "$official_file" "$local_file"
            echo "   ✅ 已複製"
            updated_count=$((updated_count + 1))
        else
            echo "   ⏭️  已跳過"
            skipped_count=$((skipped_count + 1))
        fi
        echo ""
        continue
    fi
    
    # 比較檔案內容
    if diff -q "$official_file" "$local_file" > /dev/null 2>&1; then
        echo "✓ $file - 沒有變更"
        unchanged_count=$((unchanged_count + 1))
    else
        echo "⚠️  $file - 發現變更"
        echo "   是否更新此檔案？(y/n/d 查看差異)"
        read -r answer
        
        if [ "$answer" = "d" ] || [ "$answer" = "D" ]; then
            echo ""
            echo "   --- 差異內容 ---"
            diff "$local_file" "$official_file" | head -20
            echo ""
            echo "   是否更新？(y/n)"
            read -r answer
        fi
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            # 備份原檔案
            cp "$local_file" "$local_file.backup"
            # 複製新檔案
            cp "$official_file" "$local_file"
            echo "   ✅ 已更新（備份：$file.backup）"
            updated_count=$((updated_count + 1))
        else
            echo "   ⏭️  已跳過"
            skipped_count=$((skipped_count + 1))
        fi
    fi
    echo ""
done

# 檢查 data/ 資料夾
if [ -d "$OFFICIAL_DIR/data" ]; then
    echo "📁 檢查 data/ 資料夾..."
    
    if [ ! -d "$SCRIPT_DIR/data" ]; then
        echo "   🆕 本地沒有 data/ 資料夾"
        echo "   是否從官方複製？(y/n)"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            cp -r "$OFFICIAL_DIR/data" "$SCRIPT_DIR/data"
            echo "   ✅ 已複製 data/ 資料夾"
            updated_count=$((updated_count + 1))
        fi
    else
        # 檢查 data/api_docs.txt
        if [ -f "$OFFICIAL_DIR/data/api_docs.txt" ]; then
            if ! diff -q "$OFFICIAL_DIR/data/api_docs.txt" "$SCRIPT_DIR/data/api_docs.txt" > /dev/null 2>&1; then
                echo "   ⚠️  data/api_docs.txt 有變更"
                echo "   是否更新？(y/n)"
                read -r answer
                if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                    cp "$OFFICIAL_DIR/data/api_docs.txt" "$SCRIPT_DIR/data/api_docs.txt"
                    echo "   ✅ 已更新"
                    updated_count=$((updated_count + 1))
                fi
            else
                echo "   ✓ data/api_docs.txt 沒有變更"
            fi
        fi
    fi
    echo ""
fi

# 總結
echo "================================"
echo "🎉 同步完成！"
echo ""
echo "📊 統計："
echo "   ✅ 已更新: $updated_count 個檔案"
echo "   ⏭️  已跳過: $skipped_count 個檔案"
echo "   ✓ 未變更: $unchanged_count 個檔案"
echo ""

# 如果有更新，詢問是否提交到 Git
if [ $updated_count -gt 0 ]; then
    echo "是否將變更提交到 Git？(y/n)"
    read -r commit_answer
    
    if [ "$commit_answer" = "y" ] || [ "$commit_answer" = "Y" ]; then
        cd "$SCRIPT_DIR/.." || exit
        git add week1/
        git status
        echo ""
        echo "輸入提交訊息（留空使用預設訊息）："
        read -r commit_msg
        
        if [ -z "$commit_msg" ]; then
            commit_msg="同步 Week 1 課程資料 - 更新 $updated_count 個檔案"
        fi
        
        git commit -m "$commit_msg"
        echo ""
        echo "✅ 已提交到本地 Git"
        echo ""
        echo "是否推送到 GitHub？(y/n)"
        read -r push_answer
        
        if [ "$push_answer" = "y" ] || [ "$push_answer" = "Y" ]; then
            git push
            echo "✅ 已推送到 GitHub"
        fi
    fi
fi

echo ""
echo "👋 完成！按任意鍵退出..."
read -n 1
