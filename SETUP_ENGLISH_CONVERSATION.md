# English Conversation Feature Setup

## 使用技術
- **音声認識**: Web Speech API (ブラウザ標準)
- **AI応答**: Google Gemini 1.5 Flash
- **音声合成**: Google Cloud Text-to-Speech

## 必要なAPIキー

### 1. Google Gemini API Key
最も簡単で安価な選択肢！

1. https://aistudio.google.com/apikey にアクセス
2. Googleアカウントでログイン
3. 「Create API Key」をクリック
4. APIキーをコピー

**料金:**
- 無料枠: 月150万トークンまで無料
- 有料: $0.075/1M input tokens, $0.30/1M output tokens
- 英会話練習なら月100円以下で十分

### 2. Google Cloud Text-to-Speech API (オプション)
音声読み上げが必要な場合のみ

1. https://console.cloud.google.com/ にアクセス
2. 新規プロジェクト作成
3. 「APIとサービス」→「ライブラリ」
4. 「Cloud Text-to-Speech API」を検索して有効化
5. 「認証情報」→「サービスアカウント作成」
6. JSON形式の認証情報をダウンロード

**料金:**
- 無料枠: 最初の100万文字/月無料
- 有料: Neural2 voices $16/100万文字

## Rails Credentialsの設定

```bash
EDITOR="code --wait" bundle exec rails credentials:edit
```

以下を追加:

```yaml
google:
  gemini_api_key: YOUR_GEMINI_API_KEY_HERE
  
  # TTSはオプション（音声読み上げが必要な場合のみ）
  tts_credentials_json: |
    {
      "type": "service_account",
      "project_id": "your-project-id",
      "private_key_id": "...",
      "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
      "client_email": "...",
      "client_id": "...",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "..."
    }
```

## 動作確認

1. サーバー起動:
```bash
bundle exec rails server
```

2. ブラウザでアクセス:
```
http://localhost:3000/english_conversation
```

3. マイクボタンをクリックして話す

## ブラウザ対応
- ✅ Chrome (推奨)
- ✅ Edge  
- ✅ Safari (一部制限あり)
- ❌ Firefox (Web Speech API非対応)

## トラブルシューティング

### マイクが動作しない
- ブラウザのマイク許可を確認
- HTTPSでアクセスしているか確認（本番環境）
- Chromeブラウザを使用しているか確認

### Gemini APIエラー
- APIキーが正しく設定されているか確認
- 無料枠の上限に達していないか確認
- Rails credentialsが保存されているか確認

### 音声が再生されない（TTS）
- TTSは必須ではありません（設定しなくても動作します）
- 設定する場合はGoogle Cloud Projectの課金が有効か確認

## 最小構成で始める

Gemini APIキーのみで始められます：
1. Gemini APIキーを取得（無料）
2. Credentialsに`google.gemini_api_key`を設定
3. TTSは後から追加可能（音声なしでも動作）