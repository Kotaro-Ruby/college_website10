class Nz::UniversitiesController < ApplicationController
  def index
    # TODO: ニュージーランドの大学モデルが作成されたら実装
    @universities = []
    @total_count = 0
  end

  def search
    # TODO: ニュージーランドの大学モデルが作成されたら実装
    @query = params[:q]
    @universities = []
    @total_count = 0
    render :index
  end

  def show
    # TODO: ニュージーランドの大学モデルが作成されたら実装
    redirect_to nz_about_path
  end

  def about
    # ニュージーランドの大学についてのページ
    # 静的なページなので特別な処理は不要
  end
end
