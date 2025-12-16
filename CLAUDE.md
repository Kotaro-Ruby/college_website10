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
- 絵文字は極力使わず、AIらしいデザインを排除すること
- /termsページのデザインをこのサイト全体のベースデザインとし、プロフェッショナルで落ち着いたデザインにすること

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
- タメ語で会話して。敬語禁止
- 実装は指示があった場合に開始してください。勝手に開始しないでください。

## よく使うコマンド
- サーバー起動: `bundle exec rails server`
- マイグレーション: `bundle exec rails db:migrate`
- コンソール: `bundle exec rails console`

## 大学コメント・日本語名追加の手順

### 対象大学の抽出
```ruby
# 4年制大学（carnegie_basic 15-23）、私立or州立、コメントなし
Condition.where(carnegie_basic: 15..23)
         .where(privateorpublic: ['私立', '州立'])
         .where('comment IS NULL OR comment = ?', '')
         .order(:students)
```

### コメント追加の手順
1. **情報収集**: 1校あたり10程度の英語のWebサイトを参照する
   - 大学公式サイト、US News、Niche、Princeton Review、Wikipedia(英語版)など
   - 日本語サイトは参照しない
2. **コメント作成**: 自分の言葉でまとめる（直接引用は避ける）
   - 具体的な数字やランキングを盛り込む
   - 特徴的なプログラム、強み、ユニークな点を記載
   - 4~5行ほどが推奨だが、長くても構わない（情報量重視）
   
3. **保存**: `Condition.find(id).update(comment: "...")`

### 日本語名追加の手順
1. **一般的な呼称を採用**する
   - 「サザンカリフォルニア大学」ではなく「南カリフォルニア大学」
   - 「北オハイオ大学」ではなく「オハイオノーザン大学」
   - 方角の訳し方は、日本での一般的な呼び方に従う
2. **CollegeとUniversityの訳し分け**
   - 「〇〇 College」→「〇〇カレッジ」（例：Boston College → ボストンカレッジ）
   - 「〇〇 University」→「〇〇大学」（例：Boston University → ボストン大学）
   - 「〇〇 State College」→「〇〇ステートカレッジ」または「〇〇州立カレッジ」
   - 例外：日本で別の呼び方が定着している場合はそれに従う
3. **保存**: `UniversityTranslation.create(condition_id: id, locale: 'ja', name: "...")`

## コメント・日本語訳の本番デプロイ手順

ローカルで追加したコメント・日本語訳を本番環境（Render）に反映する手順。

### 1. ローカルDBからJSONにエクスポート
```ruby
rails runner '
require "json"

# コメントデータをエクスポート
comments = {}
Condition.where.not(comment: [nil, ""]).each do |c|
  comments[c.college] = c.comment
end
File.write("db/seeds/comments_data.json", JSON.pretty_generate(comments))
puts "コメント: #{comments.count}件をエクスポート"

# 翻訳データをエクスポート
translations = []
UniversityTranslation.where(locale: "ja").each do |t|
  condition = Condition.find_by(id: t.condition_id)
  next unless condition
  translations << {さk
    college: condition.college,
    locale: t.locale,
    name: t.name
  }
end
File.write("db/seeds/translations_data.json", JSON.pretty_generate(translations))
puts "翻訳: #{translations.count}件をエクスポート"
'
```

### 2. GitにコミットしてRenderにプッシュ
```bash
git add db/seeds/comments_data.json db/seeds/translations_data.json
git commit -m "data: コメント・日本語訳データ更新"
git push
```

### 3. Renderのシェルでインポート実行
1. Renderダッシュボード → サービス → Shellタブを開く
2. デプロイ完了後、以下を実行：
```bash
bundle exec rails data:import_all
```

これでコメントと日本語訳が本番DBにインポートされる。

## ニュース記事の取得・管理ルール

### 使用するRSSフィード（無料・閲覧無料）
- **ICEF Monitor**: `https://monitor.icef.com/feed/` - 留学業界専門
- **The PIE News**: `https://thepienews.com/feed/` - 国際教育ニュース
- **Study International**: `https://www.studyinternational.com/feed/` - 留学生向け

### 許可するソース（大手・信頼性の高いメディアのみ）
- **大手通信社**: Reuters, AP, AFP
- **大手新聞**: The Guardian, The New York Times, Toronto Star, The Economic Times, The Times of India
- **大手ニュース**: BBC, CNN, CBS News, NDTV, US News
- **教育専門メディア**: Times Higher Education, The PIE News, ICEF Monitor, Study International
- **政府・公的機関**: 各国政府発表

### 除外するソース
- 大学の広報・ニュースリリース（例: Georgia Tech News Center, University of Delaware）
- 学生新聞（例: The Cornell Daily Sun, thecollegianur.com）
- 法律事務所・弁護士ブログ（例: Reddy Neumann Brown PC）
- 旅行系サイト（例: Focus on Travel News）
- マイナーな個人サイト・ブログ
- 二次情報のまとめサイト

### ニュース更新の手順
1. 上記RSSフィードから記事を取得
2. ソースが許可リストに含まれているか確認
3. タイトルと概要を日本語に翻訳
4. Newsテーブルに保存（URLで重複チェック）

### 対象国と割合
- USA: 40%
- Australia: 20%
- Canada: 20%
- New Zealand: 20%

例：10件追加する場合 → USA 4件、Australia 2件、Canada 2件、New Zealand 2件