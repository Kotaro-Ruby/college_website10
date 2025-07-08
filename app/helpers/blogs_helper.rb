module BlogsHelper
  def render_blog_content(content)
    return '' if content.blank?
    
    # マークダウン風の記法をHTMLに変換
    html = content.dup
    
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
    sanitize(html, tags: %w[h3 h4 h5 strong em a ul li blockquote img br], 
                   attributes: %w[href src alt class])
  end
end
