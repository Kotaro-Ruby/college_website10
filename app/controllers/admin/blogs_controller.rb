class Admin::BlogsController < AdminBaseController
  before_action :set_blog, only: [ :show, :edit, :update, :destroy ]

  def index
    @blogs = Blog.recent.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @blog = Blog.new
  end

  def create
    @blog = Blog.new(blog_params)

    if @blog.save
      redirect_to admin_blogs_path, notice: "ブログ記事を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @blog.update(blog_params)
      redirect_to admin_blogs_path, notice: "ブログ記事を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy
    redirect_to admin_blogs_path, notice: "ブログ記事を削除しました。"
  end

  def load_template
    template_name = params[:template]

    # ホワイトリスト方式でテンプレートを検証
    allowed_templates = Blog::TEMPLATES.keys
    unless allowed_templates.include?(template_name)
      render plain: "無効なテンプレートです", status: :bad_request
      return
    end

    # 安全なファイル名を構築
    safe_template_name = template_name.gsub(/[^a-zA-Z0-9_-]/, "")
    template_path = Rails.root.join("app", "views", "blog_templates").join("#{safe_template_name}.html.erb")

    if File.exist?(template_path) && template_path.to_s.start_with?(Rails.root.join("app", "views", "blog_templates").to_s)
      render plain: File.read(template_path)
    else
      render plain: "テンプレートが見つかりません", status: :not_found
    end
  end

  private

  def set_blog
    @blog = Blog.find_by!(slug: params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :author, :category, :published_at, :featured, :slug)
  end
end
