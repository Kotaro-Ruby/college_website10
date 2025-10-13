module SeoOptimizable
  extend ActiveSupport::Concern
  
  included do
    helper_method :page_title, :page_description, :page_keywords
  end
  
  def set_college_seo(college)
    @page_title = "#{college.name} - 学費#{number_to_currency(college.tuition, precision: 0)}、合格率#{college.acceptance_rate}%"
    @page_description = generate_college_description(college)
    @page_keywords = generate_college_keywords(college)
    
    set_structured_data(:college, {
      name: college.name,
      url: condition_url(college),
      city: college.city,
      state: college.state,
      description: @page_description,
      students: college.students,
      tuition: college.tuition
    })
    
    set_breadcrumbs([
      { name: 'ホーム', url: root_url },
      { name: '大学検索', url: search_url },
      { name: college.state, url: state_colleges_url(state: college.state) },
      { name: college.name, url: condition_url(college) }
    ])
  end
  
  def set_search_seo(params = {})
    title_parts = []
    title_parts << "#{params[:state]}州" if params[:state].present?
    title_parts << "学費#{number_to_currency(params[:tuition_max], precision: 0)}以下" if params[:tuition_max].present?
    title_parts << "合格率#{params[:acceptance_rate_min]}%以上" if params[:acceptance_rate_min].present?
    title_parts << params[:major_name] if params[:major_name].present?
    
    if title_parts.any?
      @page_title = "#{title_parts.join('・')}の大学一覧"
      @page_description = "#{title_parts.join('、')}の条件で検索した大学一覧です。詳細な情報と比較機能で最適な大学を見つけましょう。"
    else
      @page_title = "アメリカ大学検索"
      @page_description = "6,300校以上のアメリカの大学から条件に合った大学を検索。学費、合格率、専攻など詳細条件で絞り込み可能。"
    end
    
    @page_keywords = generate_search_keywords(params)
  end
  
  private
  
  def generate_college_description(college)
    parts = []
    parts << "#{college.name}は#{college.state}州#{college.city}にある大学です。"
    parts << "学生数#{number_with_delimiter(college.students)}人" if college.students.present?
    parts << "学費#{number_to_currency(college.tuition, precision: 0)}" if college.tuition.present?
    parts << "合格率#{college.acceptance_rate}%" if college.acceptance_rate.present?
    parts << "卒業率#{college.graduation_rate}%" if college.graduation_rate.present?
    parts << "SAT平均スコア#{college.sat_average}" if college.sat_average.present?
    
    "#{parts.join('、')}。詳細情報、専攻、奨学金情報などをご覧いただけます。"
  end
  
  def generate_college_keywords(college)
    keywords = [
      college.name,
      "#{college.name} 学費",
      "#{college.name} 合格率",
      "#{college.name} 偏差値",
      "#{college.name} 留学",
      college.state,
      "#{college.state}州 大学",
      college.city
    ]
    
    # 大学タイプ追加
    if college.hbcu?
      keywords << "HBCU" << "歴史的黒人大学"
    end
    if college.women_only?
      keywords << "女子大学"
    end
    if college.men_only?
      keywords << "男子大学"
    end
    
    # 主要な専攻追加
    if college.pcip_business && college.pcip_business > 0
      keywords << "ビジネス専攻"
    end
    if college.pcip_engineering && college.pcip_engineering > 0
      keywords << "エンジニアリング専攻"
    end
    if college.pcip_computer_science && college.pcip_computer_science > 0
      keywords << "コンピューターサイエンス"
    end
    
    keywords.compact.join(', ')
  end
  
  def generate_search_keywords(params)
    keywords = ['アメリカ大学', '大学検索', '留学']
    
    keywords << "#{params[:state]}州 大学" if params[:state].present?
    keywords << "学費#{params[:tuition_max]}以下" if params[:tuition_max].present?
    keywords << "合格率#{params[:acceptance_rate_min]}%以上" if params[:acceptance_rate_min].present?
    keywords << params[:major_name] if params[:major_name].present?
    keywords << "HBCU" if params[:hbcu] == 'true'
    keywords << "女子大学" if params[:women_only] == 'true'
    keywords << "コミュニティカレッジ" if params[:community_college] == 'true'
    
    keywords.join(', ')
  end
  
  def set_structured_data(type, data)
    @structured_data ||= []
    @structured_data << { type: type, data: data }
  end
  
  def set_breadcrumbs(items)
    @breadcrumbs = items
  end
  
  def page_title
    @page_title
  end
  
  def page_description
    @page_description
  end
  
  def page_keywords
    @page_keywords
  end
end