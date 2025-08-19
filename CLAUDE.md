# Claude Code Instructions

## プロジェクト概要
このプロジェクトは大学検索Webサイトです。Ruby on Railsで構築されています。
現在はアメリカ版のみ実装済みですが、今後、オーストラリア版、ニュージーランド版、カナダ版も開発予定です。

## オーストラリア版概要
- https://universitiesaustralia.edu.au/our-universities/university-profiles/　に載っている39大学を対象にする
- その39校の大学情報を　/Users/kotaro/Downloads/cricos-providers-courses-and-locations-as-at-2025-8-1-9-05-05.xlsx　から全て抽出する。

## コーディング規約
- Rubyのコードスタイルは標準的なRailsの規約に従う
- インデントは2スペース

## テスト実行コマンド
- テスト: `bundle exec rails test`
- Linter: `bundle exec rubocop`

## 重要な注意事項
- データベースのデータは絶対に削除・編集しないでください。
- production環境のデータベースには絶対に直接アクセスしない
- ユーザーの個人情報を扱う際は特に注意する
- 新機能追加時は必ずテストも書く

## データベース操作に関する厳重注意事項
### 絶対に実行してはいけないコマンド
- `rails db:drop` - データベース全体を削除する破壊的コマンド
- `rails db:reset` - データベースを削除して再作成する
- `rails db:setup` - データベースを削除して再作成する
- `Condition.destroy_all` - アメリカの大学データを全削除
- `User.destroy_all` - ユーザーデータを全削除

### 安全な代替方法
- マイグレーションのやり直し: `rails db:migrate:redo` (最新のマイグレーションのみ)
- 特定テーブルのリセット: モデル固有のデータのみを操作
- スキーマの確認: `rails db:migrate:status`
- テスト環境のみリセット: `RAILS_ENV=test rails db:reset`

### データベース操作前の確認事項
1. 現在のブランチを確認: `git branch --show-current`
2. バックアップを作成: `cp storage/development.sqlite3 storage/development.sqlite3.backup`
3. データ件数を確認: `rails runner "puts Condition.count; puts User.count"`
4. 破壊的操作が必要な場合は、必ずユーザーに確認を取る

## そのほかの注意事項
- タメ語で会話してください。
- 実装は指示があった場合に開始してください。勝手に開始しないでください。

## よく使うコマンド
- サーバー起動: `bundle exec rails server`
- マイグレーション: `bundle exec rails db:migrate`
- コンソール: `bundle exec rails console`