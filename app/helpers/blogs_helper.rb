module BlogsHelper
  def render_blog_content(content)
    return '' if content.blank?
    
    # マークダウン風の記法をHTMLに変換
    html = content.dup
    
    # ショートコードを先に処理
    html = process_shortcodes(html)
    
    # 見出し
    html.gsub!(/^### (.+)$/m, '<h5>\1</h5>')
    html.gsub!(/^## (.+)$/m, '<h4>\1</h4>')
    html.gsub!(/^# (.+)$/m, '<h3>\1</h3>')
    
    # 太字と斜体
    html.gsub!(/\*\*(.+?)\*\*/m, '<strong>\1</strong>')
    html.gsub!(/\*(.+?)\*/m, '<em>\1</em>')
    
    # リンク
    html.gsub!(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
    
    # リスト
    html.gsub!(/^- (.+)$/m, '<li>\1</li>')
    html = html.gsub(/(<li>.*<\/li>\n?)+/m) { |list| "<ul>#{list}</ul>" }
    
    # 引用
    html.gsub!(/^> (.+)$/m, '<blockquote class="blockquote">\1</blockquote>')
    
    # 画像（URLを指定）
    html.gsub!(/!\[(.+?)\]\((.+?)\)/, '<img src="\2" alt="\1" class="img-fluid">')
    
    # 改行をbrタグに
    html.gsub!(/\n/, '<br>')
    
    # XSS対策しつつHTMLを許可
    sanitize(html, tags: %w[h3 h4 h5 strong em a ul li blockquote img br div span figure figcaption], 
                   attributes: %w[href src alt class])
  end
  
  private
  
  def process_shortcodes(content)
    # [info]内容[/info] → 情報ボックス
    content.gsub!(/\[info\](.*?)\[\/info\]/m, '<div class="info-box">\1</div>')
    
    # [warning]内容[/warning] → 警告ボックス
    content.gsub!(/\[warning\](.*?)\[\/warning\]/m, '<div class="warning-box">\1</div>')
    
    # [success]内容[/success] → 成功ボックス
    content.gsub!(/\[success\](.*?)\[\/success\]/m, '<div class="success-box">\1</div>')
    
    # [highlight]内容[/highlight] → ハイライト
    content.gsub!(/\[highlight\](.*?)\[\/highlight\]/m, '<span class="highlight">\1</span>')
    
    # [quote]内容[/quote] → 大きな引用
    content.gsub!(/\[quote\](.*?)\[\/quote\]/m, '<div class="big-quote">\1</div>')
    
    # [step number="1"]内容[/step] → ステップ表示
    content.gsub!(/\[step number="(\d+)"\](.*?)\[\/step\]/m) do
      number = $1
      text = $2
      %Q{<div class="step"><div class="step-number">#{number}</div><div>#{text}</div></div>}
    end
    
    # [columns]内容[/columns] → 2カラム
    content.gsub!(/\[columns\](.*?)\[\/columns\]/m, '<div class="two-columns">\1</div>')
    
    # [column]内容[/column] → カラム内のコンテンツ
    content.gsub!(/\[column\](.*?)\[\/column\]/m, '<div>\1</div>')
    
    # [button url="URL"]テキスト[/button] → CTAボタン
    content.gsub!(/\[button url="(.+?)"\](.*?)\[\/button\]/m) do
      url = $1
      text = $2
      %Q{<a href="#{url}" class="cta-button">#{text}</a>}
    end
    
    content
  end
end
