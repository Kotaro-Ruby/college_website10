class ColumnsController < ApplicationController
  def index
    # コラム一覧を表示
    @columns = [
      {
        title: "これ以上自分を嫌いになりたくない",
        subtitle: "何も成し遂げたことがなかった私が、人生をかけて選んだ道",
        author: "運営者",
        author_bio: "College Spark編集部",
        category: "留学体験記",
        article_type: "コラム",
        published_at: "2025年7月8日",
        slug: "my-turning-point",
        excerpt: "大学の附属高校に通っていた私は、何も考えず、エスカレーター的に大学へ進むことを決めた。決めたと言っても、それが既定路線で、特に考えることもなく周りと方向を合わせただけと言っていいだろう。そんな中で気がついた「自分に自信がない」という事実が、私の人生を大きく変えることになった...",
        url: "/p/my-turning-point",
        featured: true,
        tags: [ "挑戦", "自信", "海外進学", "転機" ]
      }
    ]

    # 将来的にはBlogモデルに type フィールドを追加して
    # @columns = Blog.where(article_type: 'column').published.recent
  end
end
