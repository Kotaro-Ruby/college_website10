# Render本番環境でのデータ移行手順

## 方法1: Render Shell経由でRakeタスク実行

### 1. Renderダッシュボードにアクセス
- https://dashboard.render.com/ にログイン
- あなたのアプリケーションを選択

### 2. Shell/Console機能を使用
- アプリケーション詳細ページで「Shell」タブをクリック
- または「Connect」ボタンから「Shell」を選択

### 3. 以下のコマンドを順番に実行

```bash
# 1. マイグレーションを実行（必要に応じて）
rails db:migrate

# 2. 専攻データのインポート（既存のタスク）
rails college_data:import_major_data

# 3. コメントの追加
rails college_data:add_comments

# 4. 詳細プログラムデータのインポート（時間がかかる場合があります）
rails college_data:import_full_program_data
```

### 4. 実行状況の確認
各コマンドの完了を待ってから次のコマンドを実行してください。

## 方法2: PostgreSQLに切り替え（推奨）

### 1. PostgreSQLアドオンの追加
- Renderダッシュボードで「New +」→「PostgreSQL」を選択
- データベースを作成

### 2. Gemfileの更新
```ruby
# 本番環境用
group :production do
  gem 'pg'
end

# 開発環境用
group :development, :test do
  gem 'sqlite3', '>= 2.1'
end
```

### 3. database.ymlの更新
```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['DATABASE_URL'] %>
```

### 4. 環境変数の設定
Render環境変数にDATABASE_URLを設定（PostgreSQL作成時に自動設定されます）

## 注意事項

- SQLiteは本番環境での使用が推奨されません
- データの永続化を確実にするためにはPostgreSQLの使用を強く推奨します
- Renderでは再デプロイ時にSQLiteファイルが削除される可能性があります

## 現在のRakeタスク一覧

```bash
# 専攻データのインポート
rails college_data:import_major_data

# 大学コメントの追加
rails college_data:add_comments

# 詳細プログラムデータのインポート
rails college_data:import_full_program_data

# 新しい大学データのインポート（授業料付き）
rails college_data:import_fresh_colleges
```