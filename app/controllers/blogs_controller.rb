class BlogsController < ApplicationController
  def index
    @blogs = Blog.published.recent
    @blogs = @blogs.by_category(params[:category]) if params[:category].present?
    @blogs = @blogs.page(params[:page]).per(10)
    @categories = Blog::CATEGORIES

    # 静的記事
    @static_articles = [
      {
        title: "これ以上自分を嫌いになりたくない",
        subtitle: "何も成し遂げたことがなかった私が、人生をかけて選んだ道",
        excerpt: "大学の附属高校に通っていた私は、何も考えず、エスカレーター的に大学へ進むことを決めた。決めたと言っても、それが既定路線で、特に考えることもなく周りと方向を合わせただけと言っていいだろう。そんな中で気がついた「自分に自信がない」という事実が、私の人生を大きく変えることになった...",
        author: "運営者",
        category: "留学体験記",
        published_at: Date.parse("2025-07-08"),
        slug: "my-turning-point",
        url: "/p/my-turning-point"
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
    redirect_to blogs_path, alert: "ブログ記事が見つかりません。"
  end
end
