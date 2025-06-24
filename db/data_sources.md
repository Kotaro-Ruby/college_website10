# College Spark データソース情報

## 現在使用中のデータソース
1. **College Scorecard** (https://collegescorecard.ed.gov/)
   - 基本情報（州、学生数、卒業率など）
   - 授業料データ（TUITIONFEE_IN, TUITIONFEE_OUT）
   - GPAデータ

## 追加可能なデータソース

### NCAA情報
1. **NCAA公式サイト** (https://www.ncaa.org/)
   - Division I, II, III の分類
   - カンファレンス情報
   - スポーツプログラム一覧

2. **College Football Data API** (無料)
   - https://collegefootballdata.com/
   - フットボールに特化したデータ
   - REST APIで簡単にアクセス可能

3. **Wikipedia API**
   - 各大学のInfoboxからNCAA情報を抽出可能
   - 無料で利用可能

### 授業料詳細情報
1. **IPEDS (Integrated Postsecondary Education Data System)**
   - https://nces.ed.gov/ipeds/
   - より詳細な財務データ
   - 州内/州外、寮費、その他の費用

2. **College Board**
   - 授業料の推移データ
   - 奨学金情報

## 実装推奨順序
1. College Scorecardの授業料データを正しく取得・表示
2. NCAA Division情報を手動でシードデータとして追加
3. 必要に応じて外部APIを統合

## データ更新頻度
- College Scorecard: 年1回更新
- NCAA情報: シーズンごとに変更の可能性
- 授業料: 年度ごとに更新