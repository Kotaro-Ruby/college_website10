#!/usr/bin/env bash
# exit on error
set -o errexit

# Build commands for Render deployment
echo "=== Render Build Script Starting (v3) ==="

# Install dependencies
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate

# Run seeds (日本語名データなど)
bundle exec rails db:seed

# Check if data setup is needed
echo "=== Checking if data setup is needed ==="

COLLEGES_WITH_COMMENTS=$(bundle exec rails runner "puts Condition.where.not(comment: [nil, '']).count" 2>/dev/null || echo "0")
TOTAL_COLLEGES=$(bundle exec rails runner "puts Condition.count" 2>/dev/null || echo "0")
COLLEGES_WITH_MAJORS=$(bundle exec rails runner "puts Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count" 2>/dev/null || echo "0")

echo "Colleges with comments: $COLLEGES_WITH_COMMENTS"
echo "Total colleges: $TOTAL_COLLEGES"
echo "Colleges with majors: $COLLEGES_WITH_MAJORS"

# Check if compressed data file exists
if [ -f "db/college_data_compressed.json.gz" ]; then
    echo "=== Compressed data file found, will be processed in releaseCommand ==="
else
    echo "=== No compressed data file found - will be handled in releaseCommand ==="
fi

# サンプルデータの自動生成を無効化
# ユーザーの6321校のローカルデータのみを使用

echo "=== Render Build Script Completed ==="