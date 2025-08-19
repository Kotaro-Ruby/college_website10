class ComparisonsController < ApplicationController
  before_action :require_login

  # 比較ページ表示
  def index
    @colleges = []
    comparison_list = current_user.comparison_list
    if comparison_list.any?
      @colleges = Condition.where(id: comparison_list)
    end
  end

  # 比較リストに追加
  def create
    condition_id = params[:condition_id].to_i
    comparison_list = current_user.comparison_list

    if comparison_list.include?(condition_id)
      render json: { status: "error", message: "この大学は既に比較リストに追加されています" }
    elsif comparison_list.length >= 4
      render json: { status: "error", message: "比較できる大学は最大4校までです" }
    else
      comparison_list << condition_id
      current_user.update(comparison_list: comparison_list)
      render json: {
        status: "success",
        message: "比較リストに追加しました",
        count: comparison_list.length
      }
    end
  end

  # 比較リストから削除
  def destroy
    condition_id = params[:condition_id].to_i
    comparison_list = current_user.comparison_list
    comparison_list.delete(condition_id)
    current_user.update(comparison_list: comparison_list)

    render json: {
      status: "success",
      message: "比較リストから削除しました",
      count: comparison_list.length
    }
  end

  # 比較リスト全削除
  def clear
    current_user.update(comparison_list: [])

    render json: {
      status: "success",
      message: "比較リストをクリアしました",
      count: 0
    }
  end

  private

  def require_login
    unless logged_in?
      render json: { status: "error", message: "ログインが必要です" }, status: :unauthorized
    end
  end
end
