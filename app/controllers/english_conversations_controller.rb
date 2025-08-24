class EnglishConversationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:process_speech, :text_to_speech, :clear_history, :get_initial_message]
  
  def index
    @conversation_history = session[:conversation_history] || []
  end
  
  def process_speech
    user_input = params[:text]
    situation = params[:situation] || 'free'
    
    # Gemini APIに送信して応答を生成
    response = generate_gemini_response(user_input, situation)
    
    # エラーの場合はデフォルトメッセージを使用し、履歴には保存しない
    if response.nil?
      response = "Sorry, the AI service is temporarily unavailable (rate limit reached). Please wait a moment and try again, or use the silent mode with simple responses."
    else
      # 成功した場合のみ会話履歴を更新
      update_conversation_history(user_input, response)
    end
    
    render json: { 
      response: response,
      conversation_history: session[:conversation_history]
    }
  end
  
  def text_to_speech
    text = params[:text]
    
    # Google TTS APIで音声データに変換
    audio_data = generate_audio(text)
    
    if audio_data
      render json: { audio: Base64.encode64(audio_data) }
    else
      render json: { error: "Failed to generate audio" }, status: :unprocessable_entity
    end
  end
  
  def clear_history
    session[:conversation_history] = []
    render json: { status: "success" }
  end
  
  def get_initial_message
    situation = params[:situation] || 'free'
    
    # 各シチュエーションの初回メッセージ
    initial_messages = {
      'free' => "Hello! I'm your English conversation tutor. What would you like to talk about today?",
      'restaurant' => "Good evening! Welcome to The Garden Restaurant. Do you have a reservation for tonight?",
      'shopping' => "Hello! Welcome to our store. How can I help you today? Are you looking for something specific?",
      'airport' => "Good morning! Welcome to the airport. Which airline are you flying with today?",
      'job-interview' => "Good morning! Thank you for coming to the interview. Please have a seat. Could you start by telling me a little about yourself?",
      'hotel' => "Good afternoon! Welcome to Grand Hotel. How may I assist you today? Do you have a reservation?",
      'doctor' => "Hello! I'm Dr. Smith. What brings you in today? How are you feeling?",
      'school' => "Good morning! Welcome to the academic advising office. How can I help you with your studies today?"
    }
    
    message = initial_messages[situation] || initial_messages['free']
    
    render json: { 
      response: message,
      situation: situation
    }
  end
  
  private
  
  def generate_gemini_response(user_input, situation = 'free')
    api_key = Rails.application.credentials.dig(:google, :gemini_api_key)
    
    Rails.logger.info "API Key loaded: #{api_key.present? ? 'Yes' : 'No'}"
    Rails.logger.info "API Key starts with: #{api_key[0..10]}..." if api_key
    
    unless api_key
      Rails.logger.error "Gemini API key not configured"
      return nil  # Return nil to indicate error without saving to history
    end
    
    client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: api_key
      },
      options: { 
        model: 'gemini-1.5-flash',
        server_sent_events: false 
      }
    )
    
    # 会話履歴を含めたプロンプトを構築
    messages = build_gemini_messages(user_input, situation)
    
    Rails.logger.info "Sending messages to Gemini: #{messages.inspect}"
    
    # Gemini APIにリクエスト
    result = client.generate_content({
      contents: messages,
      generation_config: {
        temperature: 0.7,
        max_output_tokens: 150,
        top_p: 0.8,
        top_k: 40
      }
    })
    
    # レスポンスからテキストを抽出
    result.dig('candidates', 0, 'content', 'parts', 0, 'text') || 
      "I'm sorry, I couldn't understand that. Could you try again?"
      
  rescue => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil  # Return nil to indicate error without saving to history
  end
  
  def generate_audio(text)
    require "google/cloud/text_to_speech"
    
    # JSONファイルから認証情報を読み込む
    credentials_path = Rails.root.join('config', 'tts-credentials.json')
    
    unless File.exist?(credentials_path)
      Rails.logger.warn "Google TTS credentials file not found - skipping audio generation"
      return nil
    end
    
    client = Google::Cloud::TextToSpeech.text_to_speech do |config|
      config.credentials = credentials_path.to_s
    end
    
    synthesis_input = { text: text }
    
    voice = {
      language_code: "en-US",
      name: "en-US-Neural2-F",
      ssml_gender: "FEMALE"
    }
    
    audio_config = {
      audio_encoding: "MP3",
      speaking_rate: 0.9
    }
    
    response = client.synthesize_speech(
      input: synthesis_input,
      voice: voice,
      audio_config: audio_config
    )
    
    response.audio_content
  rescue => e
    Rails.logger.error "Google TTS Error: #{e.message}"
    nil
  end
  
  def build_gemini_messages(user_input, situation = 'free')
    messages = []
    
    # 会話履歴から過去のメッセージを構築
    conversation_history = session[:conversation_history] || []
    
    Rails.logger.info "Raw conversation history: #{conversation_history.inspect}"
    
    # エラーメッセージを除外して有効な会話のみを取得
    valid_history = conversation_history.select do |exchange|
      exchange[:assistant] && 
      !exchange[:assistant].include?("I'm having trouble") && 
      !exchange[:assistant].include?("API key is not configured")
    end
    
    Rails.logger.info "Valid conversation history count: #{valid_history.length}"
    Rails.logger.info "Valid conversation history: #{valid_history.inspect}"
    
    # シチュエーションに応じたプロンプトを設定
    situation_prompts = {
      'free' => "You are an English conversation tutor. Help the user practice English conversation.",
      'restaurant' => "You are a waiter/waitress at a restaurant. The user is a customer. Take their order, suggest menu items, and help them with their dining experience.",
      'shopping' => "You are a shop assistant at a retail store. Help the customer find what they need, answer questions about products, and assist with purchases.",
      'airport' => "You are an airport staff member. Help the traveler with check-in, security, boarding, and travel-related questions.",
      'job-interview' => "You are a job interviewer. Ask professional questions about the candidate's experience, skills, and qualifications. Be formal but friendly.",
      'hotel' => "You are a hotel receptionist. Help the guest with check-in, room information, and hotel services.",
      'doctor' => "You are a doctor or medical receptionist. Help the patient describe their symptoms and schedule appointments. Be professional and caring.",
      'school' => "You are a teacher or academic advisor. Help the student with course information, assignments, and academic questions."
    }
    
    base_prompt = situation_prompts[situation] || situation_prompts['free']
    
    # 初回または有効な履歴がない場合はシステムプロンプトを含める
    if valid_history.empty?
      system_prompt = "#{base_prompt} " \
                     "Respond naturally and encouragingly. Keep responses concise and conversational (2-3 sentences max). " \
                     "Correct any major errors gently. Be friendly and supportive. Stay in character for the situation.\n\n" \
                     "User: #{user_input}"
      messages << {
        role: "user",
        parts: [{ text: system_prompt }]
      }
    else
      # システムプロンプトを最初に追加
      system_prompt = "#{base_prompt} Keep responses concise (2-3 sentences max). Stay in character."
      messages << {
        role: "user",
        parts: [{ text: system_prompt }]
      }
      messages << {
        role: "model",
        parts: [{ text: "I understand. I'll help you practice English conversation." }]
      }
      
      # Gemini用のフォーマットに変換（最新5つまで）
      valid_history.last(5).each do |exchange|
        messages << {
          role: "user",
          parts: [{ text: exchange[:user] }]
        }
        messages << {
          role: "model",
          parts: [{ text: exchange[:assistant] }]
        }
      end
      
      # 現在のユーザー入力を追加
      messages << {
        role: "user",
        parts: [{ text: user_input }]
      }
    end
    
    messages
  end
  
  def update_conversation_history(user_input, response)
    session[:conversation_history] ||= []
    session[:conversation_history] << { 
      user: user_input, 
      assistant: response,
      timestamp: Time.current
    }
    
    # 履歴が長くなりすぎないように制限（最新10個まで）
    if session[:conversation_history].length > 10
      session[:conversation_history] = session[:conversation_history].last(10)
    end
  end
end