class BlogsController < ApplicationController
  def index
    @blogs = Blog.published.recent
    @blogs = @blogs.by_category(params[:category]) if params[:category].present?
    @blogs = @blogs.page(params[:page]).per(10)
    @categories = Blog::CATEGORIES
  end

  def show
    @blog = Blog.published.find_by!(slug: params[:slug])
    @related_blogs = Blog.published
                         .where.not(id: @blog.id)
                         .by_category(@blog.category)
                         .recent
                         .limit(3)
  rescue ActiveRecord::RecordNotFound
    redirect_to blogs_path, alert: 'ブログ記事が見つかりません。'
  end
end
