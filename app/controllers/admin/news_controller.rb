class Admin::NewsController < ApplicationController
  before_action :set_news, only: [ :edit, :update, :publish, :archive ]

  def index
    @news = News.order(created_at: :desc).page(params[:page]).per(20)
    @draft_count = News.draft.count
    @published_count = News.published.count
  end

  def fetch
    result = NewsFetcherService.fetch_and_save

    flash[:notice] = "ニュース取得完了: #{result[:fetched]}件取得、#{result[:saved]}件保存、#{result[:skipped]}件スキップ"
    redirect_to admin_news_index_path
  end

  def edit
  end

  def update
    if @news.update(news_params)
      flash[:notice] = "ニュースを更新しました"
      redirect_to admin_news_index_path
    else
      render :edit
    end
  end

  def publish
    if @news.update(status: :published)
      flash[:notice] = "ニュースを公開しました"
    else
      flash[:alert] = "公開に失敗しました"
    end
    redirect_to admin_news_index_path
  end

  def archive
    if @news.update(status: :archived)
      flash[:notice] = "ニュースをアーカイブしました"
    else
      flash[:alert] = "アーカイブに失敗しました"
    end
    redirect_to admin_news_index_path
  end

  def destroy
    @news = News.find(params[:id])
    @news.destroy
    flash[:notice] = "ニュースを削除しました"
    redirect_to admin_news_index_path
  end

  private

  def set_news
    @news = News.find(params[:id])
  end

  def news_params
    params.require(:news).permit(
      :title,
      :url,
      :description,
      :image_url,
      :published_at,
      :source,
      :country,
      :japanese_title,
      :japanese_description,
      :status
    )
  end
end
