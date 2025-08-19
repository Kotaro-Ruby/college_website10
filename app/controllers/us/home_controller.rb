class Us::HomeController < ApplicationController
  def index
    # アメリカ版のトップページ
    redirect_to us_universities_path
  end
end
