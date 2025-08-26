class Us::HomeController < ApplicationController
  def index
    # アメリカ版のトップページ
    # 既存のアメリカ大学検索ページにリダイレクト
    redirect_to search_path
  end
end
