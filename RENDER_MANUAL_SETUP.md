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
# セットアップ
rails render:setup_data
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
2. `rails render:setup_data`でデータを追加
3. ブラウザで動作確認