class Ca::UniversitiesController < ApplicationController
  def index
    # TODO: カナダの大学モデルが作成されたら実装
    @universities = []
    @total_count = 0
  end

  def search
    # TODO: カナダの大学モデルが作成されたら実装
    @query = params[:q]
    @universities = []
    @total_count = 0
    render :index
  end

  def show
    # TODO: カナダの大学モデルが作成されたら実装
    redirect_to ca_about_path
  end

  def about
    # 国の基本情報を取得
    @country = Country.find_by(code: 'CA')
    # カナダの大学についてのページ
    # 静的なページなので特別な処理は不要
  end
end
