# College Scorecard API セットアップガイド

## 1. APIキーの取得（無料）

1. [College Scorecard API Documentation](https://collegescorecard.ed.gov/data/documentation/) にアクセス

2. ページ内の "Get an API Key" セクションを探す

3. メールアドレスを入力して送信
   - 即座にAPIキーがメールで送られてきます
   - 完全無料、クレジットカード不要

## 2. 環境変数の設定

### macOS/Linux:
```bash
export COLLEGE_SCORECARD_API_KEY="あなたのAPIキー"
```

### Windows:
```cmd
set COLLEGE_SCORECARD_API_KEY=あなたのAPIキー
```

### .envファイルを使用する場合:
```
COLLEGE_SCORECARD_API_KEY=あなたのAPIキー
```

## 3. 授業料データの更新

### 全大学の授業料を更新:
```bash
rails update:tuition
```

### 特定の州のみ更新:
```bash
# カリフォルニア州の例
rails update:tuition_by_state[CA]

# オハイオ州の例  
rails update:tuition_by_state[OH]
```

## 4. データの説明

### Net Price（実質価格）とは？
- 授業料から平均的な奨学金・助成金を差し引いた金額
- 学生が実際に支払う金額により近い数値

### 州立大学の場合
- Out-of-State（州外）学生の料金を使用
- より多くの学生に適用される金額

### 私立大学の場合
- 全学生共通の料金
- Net Priceを優先的に使用

## 5. トラブルシューティング

### APIキーが無効と表示される場合
- キーの前後に余分なスペースがないか確認
- 引用符が正しいか確認

### データが取得できない場合
- 大学名が正確に一致しているか確認
- APIの利用制限（1000リクエスト/時）に注意

## 6. データ更新頻度
- College Scorecardは年1回更新
- 最新データは通常9月〜10月に公開