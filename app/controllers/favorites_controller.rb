class FavoritesController < ApplicationController
  before_action :require_login

  # お気に入り一覧
  def index
    @favorites = current_user.favorite_conditions.includes(:favorites)
  end

  # お気に入り追加
  def create
    @condition = Condition.find(params[:condition_id])
    @favorite = current_user.favorites.build(condition: @condition)

    if @favorite.save
      render json: { status: "success", message: "お気に入りに追加しました", favorited: true }
    else
      render json: { status: "error", message: @favorite.errors.full_messages.first, favorited: false }
    end
  end

  # お気に入り削除
  def destroy
    @condition = Condition.find(params[:condition_id])
    @favorite = current_user.favorites.find_by(condition: @condition)

    if @favorite&.destroy
      render json: { status: "success", message: "お気に入りから削除しました", favorited: false }
    else
      render json: { status: "error", message: "お気に入りの削除に失敗しました", favorited: true }
    end
  end

  private

  def require_login
    unless logged_in?
      if request.xhr?
        render json: { status: "error", message: "ログインが必要です" }
      else
        redirect_to login_path, alert: "ログインが必要です"
      end
    end
  end
end
