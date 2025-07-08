class BlogsController < ApplicationController
  def index
    @blogs = Blog.published.recent
    @blogs = @blogs.by_category(params[:category]) if params[:category].present?
    @blogs = @blogs.page(params[:page]).per(10)
    @categories = Blog::CATEGORIES
    
    # 静的記事も追加
    @static_articles = [
      {
        title: "自信を失った私を変えた一つの決断",
        subtitle: "何も成し遂げたことがなかった私が、人生をかけて選んだ道",
        author: "運営者",
        category: "体験談",
        published_at: "2025年7月8日",
        slug: "my-turning-point",
        excerpt: "大学の附属高校に通っていた私は、何も考えず、エスカレーター的に大学へ進むことを決めた。決めたと言っても、それが既定路線で、特に考えることもなく周りと方向を合わせただけと言っていいだろう。そんな中で気がついた「自分に自信がない」という事実が、私の人生を大きく変えることになった...",
        url: "/p/my-turning-point",
        featured: true
      }
    ]
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
