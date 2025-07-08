#!/bin/bash

# バックアップ作成
cd ~/College\ Finder/college_website10
rails backup:create

# Google Driveにコピー（パスは環境に合わせて変更）
GOOGLE_DRIVE_PATH=~/Google\ Drive/CollegeSpark_Backups
ICLOUD_PATH=~/Library/Mobile\ Documents/com~apple~CloudDocs/CollegeSpark_Backups

# Google Driveフォルダが存在する場合
if [ -d "$GOOGLE_DRIVE_PATH" ]; then
    echo "📤 Uploading to Google Drive..."
    cp backups/full_backup_*.json.gz "$GOOGLE_DRIVE_PATH/"
    cp backups/colleges_backup_*.csv "$GOOGLE_DRIVE_PATH/" 2>/dev/null || true
    echo "✅ Google Drive backup completed"
fi

# iCloudフォルダが存在する場合
if [ -d "$ICLOUD_PATH" ]; then
    echo "☁️  Uploading to iCloud..."
    cp backups/full_backup_*.json.gz "$ICLOUD_PATH/"
    cp backups/colleges_backup_*.csv "$ICLOUD_PATH/" 2>/dev/null || true
    echo "✅ iCloud backup completed"
fi

# 古いローカルバックアップを削除（30日以上前）
find backups/ -name "*.json.gz" -mtime +30 -delete
find backups/ -name "*.sqlite3" -mtime +30 -delete

echo "🎉 All backups completed!"