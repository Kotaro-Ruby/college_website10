# Google TTS Setup for Production

## 環境変数の設定

本番環境でGoogle Text-to-Speech APIを使用するには、環境変数を設定する必要があります。

### 1. TTS認証情報のJSONを準備

`config/tts-credentials.json`の内容を1行のJSON文字列に変換：

```bash
cat config/tts-credentials.json | jq -c .
```

### 2. 環境変数を設定

#### Herokuの場合：
```bash
heroku config:set GOOGLE_TTS_CREDENTIALS='{"type":"service_account","project_id":"cs-english-conversation",...}'
```

#### Renderの場合：
Renderのダッシュボードで環境変数を設定：
- Key: `GOOGLE_TTS_CREDENTIALS`
- Value: 上記で生成した1行のJSON文字列

#### その他のホスティングサービス：
環境変数 `GOOGLE_TTS_CREDENTIALS` にTTS認証情報のJSON文字列を設定してください。

## 動作確認

1. 本番環境のログを確認：
   - "Using TTS credentials from environment variable" が表示されていれば環境変数から読み込み成功
   - "Using TTS credentials from local file" が表示されていれば、ローカルファイルから読み込み（開発環境）
   - "Google TTS credentials not found - using browser TTS fallback" が表示されていれば、ブラウザのTTSにフォールバック

2. 英会話ページでテスト：
   - シチュエーションを選択
   - 会話を開始
   - AIの返答が**Google TTSの高品質な音声**で再生されることを確認

## トラブルシューティング

### 音声が再生されない場合：
1. ブラウザのコンソールログを確認
2. "Using browser TTS" と表示されている場合は、Google TTSの認証情報が正しく設定されていない
3. 環境変数が正しく設定されているか確認

### API制限エラーの場合：
- Google Cloud ConsoleでTTS APIの使用量を確認
- 必要に応じてクォータを増やす

## セキュリティ注意事項

- **認証情報をGitHubにコミットしない**
- `.gitignore`に`config/tts-credentials.json`が含まれていることを確認
- 環境変数は安全に管理する