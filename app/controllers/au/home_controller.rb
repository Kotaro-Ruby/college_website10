class Au::HomeController < ApplicationController
  def index
    # オーストラリア版のトップページ
    redirect_to au_universities_path
  end
end