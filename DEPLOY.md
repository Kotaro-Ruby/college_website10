# デプロイ設定

## Render.comでのデプロイ

### 重要：Start Commandの設定

Renderのダッシュボードで以下のStart Commandを設定してください：

```bash
bundle exec rails db:migrate && bundle exec rails db:safe_reset_conditions && if [ -f "db/college_data_compressed.json.gz" ]; then cp db/college_data_compressed.json.gz tmp/ && bundle exec rails import:from_compressed; fi && bundle exec rails db:seed && bundle exec puma -C config/puma.rb
```

このコマンドは以下の処理を実行します：
1. `rails db:migrate` - データベースマイグレーション
2. `rails db:safe_reset_conditions` - 既存データの安全なリセット
3. `import:from_compressed` - アメリカの大学データ（6321校）のインポート
4. `rails db:seed` - オーストラリアの大学データ（39校）のインポート
5. `puma` - Webサーバーの起動

### データファイル

以下のデータファイルがリポジトリに含まれています：
- `db/college_data_compressed.json.gz` - アメリカの大学データ（圧縮済み）
- `data/australia/universities.json` - オーストラリアの大学データ

### 環境変数

以下の環境変数をRenderで設定してください：
- `DATABASE_URL` - PostgreSQLデータベースURL（自動設定）
- `RAILS_ENV` - production
- `RAILS_MASTER_KEY` - config/master.keyの値
- `SECRET_KEY_BASE` - セキュアなランダム文字列