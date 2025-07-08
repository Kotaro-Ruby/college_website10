class PagesController < ApplicationController
  def show
    @page = params[:page]
    
    # セキュリティ: ディレクトリトラバーサル対策
    unless @page.match?(/\A[a-z0-9_-]+\z/)
      raise ActionController::RoutingError.new('Not Found')
    end
    
    # ページが存在するかチェック
    template_path = "pages/#{@page}"
    unless template_exists?(template_path)
      raise ActionController::RoutingError.new('Not Found')
    end
    
    render template: template_path
  end
  
  private
  
  def template_exists?(path)
    lookup_context.exists?(path, [], false)
  end
end