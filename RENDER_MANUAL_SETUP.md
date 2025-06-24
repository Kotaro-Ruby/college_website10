# Render手動セットアップ手順

## 問題の原因
Renderのビルド時間制限により、大量のデータ処理が完了前にタイムアウトしている可能性があります。

## 解決方法1: 環境変数の設定確認

1. Renderダッシュボードで環境変数を確認：
   ```
   COLLEGE_SCORECARD_API_KEY = eFbenl6AhOp1FYATeuHHTa4nXQZYsRi7w3JNxcBl
   ```

2. 設定されていない場合は追加してデプロイ

## 解決方法2: ワンクリックデプロイ後手動実行

### A. Console/Shellが使用可能な場合
1. Renderダッシュボード → アプリ選択 → Shell
2. 以下のコマンドを実行：

```bash
# 高速セットアップ（コメントのみ）
rails render:quick_setup

# または完全セットアップ
rails render:setup_data
```

### B. Console/Shellが使用できない場合

#### 方法1: 一時的なコントローラー作成
以下のコントローラーを一時的に作成し、ブラウザからアクセス：

`app/controllers/admin_controller.rb`を作成：
```ruby
class AdminController < ApplicationController
  def setup_data
    # セキュリティのため、特定のパラメータでのみ実行
    if params[:secret] == 'setup123'
      require_relative '../../lib/college_comment_generator'
      
      count = 0
      Condition.where(comment: [nil, '']).limit(1000).find_each do |college|
        comment_data = {
          students: college.students,
          acceptance_rate: college.acceptance_rate,
          ownership: college.privateorpublic
        }
        
        comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
        college.update(comment: comment)
        count += 1
      end
      
      render plain: "セットアップ完了！#{count}件のコメントを追加しました。"
    else
      render plain: "アクセス拒否"
    end
  end
end
```

`config/routes.rb`に追加：
```ruby
get '/admin/setup', to: 'admin#setup_data'
```

ブラウザで以下のURLにアクセス：
```
https://your-app-name.onrender.com/admin/setup?secret=setup123
```

#### 方法2: GitHub Actionsの使用
`.github/workflows/render-setup.yml`を作成：
```yaml
name: Render Data Setup
on:
  workflow_dispatch:

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup data via API
        run: |
          curl -X GET "https://your-app-name.onrender.com/admin/setup?secret=setup123"
```

## 解決方法3: ビルドスクリプトの最適化

`bin/render-build.sh`を以下に変更：

```bash
#!/usr/bin/env bash
set -o errexit

echo "=== Render Build Script Starting ==="

# Install dependencies
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate

# Quick comment setup only (fast)
echo "=== Adding comments only ==="
bundle exec rails render:quick_setup

echo "=== Render Build Script Completed ==="
```

## 確認方法

セットアップ後、以下で確認：

```bash
# データベース内容確認
rails runner "
puts 'Total colleges: ' + Condition.count.to_s
puts 'With comments: ' + Condition.where.not(comment: [nil, '']).count.to_s
puts 'With tuition: ' + Condition.where.not(tuition: [nil, 0]).count.to_s
puts 'With majors: ' + Condition.where('pcip_business > 0 OR pcip_engineering > 0').count.to_s
"
```

## 推奨手順

1. まず環境変数を確認・設定
2. `rails render:quick_setup`でコメントを追加
3. 必要に応じて`rails render:setup_data`で残りのデータを追加
4. ブラウザで動作確認

## 緊急時対応

すべてが失敗した場合：
1. 一時的なadminコントローラーを作成
2. ブラウザ経由でセットアップ実行
3. セットアップ完了後、adminコントローラーを削除

この方法なら確実にデータが追加されます。