class Nz::HomeController < ApplicationController
  def index
    # ニュージーランド版のトップページ
    redirect_to nz_universities_path
  end
end
