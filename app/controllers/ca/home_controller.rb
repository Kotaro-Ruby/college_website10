class Ca::HomeController < ApplicationController
  def index
    # カナダ版のトップページ
    redirect_to ca_universities_path
  end
end
