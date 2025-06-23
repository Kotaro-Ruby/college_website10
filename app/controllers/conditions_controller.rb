class ConditionsController < ApplicationController
  # 結果を取得するメインアクション
  def results
    scope = Condition.all

    # 大学名検索の処理
    if params[:college_name].present?
      college_name = params[:college_name].strip.downcase
      
      # 複数の検索パターンを試す
      search_patterns = [
        college_name,                           # 完全一致
        college_name.gsub(/[^a-z0-9\s]/, ''),   # 特殊文字を削除
        college_name.gsub(/\s+/, ''),           # スペースを削除
        college_name.split.join('%')            # 単語間に%を挿入
      ]
      
      # 各パターンでOR検索
      conditions = search_patterns.map do |pattern|
        "LOWER(REPLACE(college, ' ', '')) LIKE ?"
      end.join(' OR ')
      
      search_values = search_patterns.map { |pattern| "%#{pattern.gsub(/\s+/, '')}%" }
      
      scope = scope.where(conditions, *search_values)
      @results = scope
      Rails.logger.debug("College name search: #{college_name}")
      Rails.logger.debug("Search patterns: #{search_patterns}")
      Rails.logger.debug("Generated SQL Query: #{@results.to_sql}")
      return
    end

    # State の処理
    if params[:state].blank? || params[:state] == '選択してください'
      if request.xhr?  # Ajaxリクエストの場合
        render json: { error: '州を選択してください' }, status: :unprocessable_entity and return
      else
        flash.now[:error] = '州を選択してください'
        render :index and return
      end
    elsif params[:state] != '指定しない'
      state = params[:state]
      scope = scope.where('state = ?', state)
    end

    #privateorpublicの処理
      if params[:privateorpublic].present? && params[:privateorpublic] !='指定しない'
        privateorpublic = params[:privateorpublic]
        scope = scope.where('privateorpublic = ?', privateorpublic)
      end

    # Tuition の処理
      if params[:tuition].present?
        tuition_range = parse_tuition_range(params[:tuition])
        if tuition_range
          Rails.logger.debug("Tuition range is valid: #{tuition_range.inspect}")
    # tuition_range[1] が無限大の場合、100000（または適切な最大金額）に設定する
      max_tuition = tuition_range[1] == Float::INFINITY ? 999_999 : tuition_range[1]
    # 範囲が有効な場合のみ、範囲を適用
      scope = scope.where('tuition BETWEEN ? AND ?', tuition_range[0], max_tuition)
    else
      Rails.logger.debug("Invalid tuition range: #{params[:tuition]}")
        end
      end

    # Students の処理
      if params[:students].present?
        students_ranges = parse_students_range(params[:students])  # 複数の範囲を処理

        if students_ranges
          # 複数の範囲を OR 条件で処理する場合
          scope = scope.where('(' + students_ranges.map { |range| 'students BETWEEN ? AND ?' }.join(' OR ') + ')', *students_ranges.flatten)
        else
          Rails.logger.debug("Invalid students range: #{params[:students]}")
        end
      end

  # GPAの処理
  if params[:gpa].present?
    gpa_range = parse_gpa_range(params[:gpa])
    if gpa_range
      Rails.logger.debug("GPA range is valid: #{gpa_range.inspect}")
      # 範囲内のデータとnil（N/A）を検索に含める
      scope = scope.where('GPA BETWEEN ? AND ?', gpa_range[0], gpa_range[1]).or(scope.where(GPA: nil))
      Rails.logger.debug("Query for GPA: #{scope.to_sql}")
    else
      Rails.logger.debug("Invalid GPA range: #{params[:gpa]}")
      flash[:error] = "Invalid GPA range selected. Please select a valid range (e.g., 0.0~5.0)."
    end
  else
    # GPAが指定されていない場合、N/A（nil）も含める
    scope = scope.or(scope.where(GPA: nil))
    Rails.logger.debug("Query for GPA N/A: #{scope.to_sql}")
  end

      
  # Division の処理
  if params[:Division].present?
    divisions = params[:Division].split(',') # 選択肢がカンマ区切りで渡されることを想定
    if divisions.include?('すべて')
      # 「すべて」が含まれている場合、Division の条件を無視
      Rails.logger.debug("All Divisions selected, no filtering applied.")
    else
      # OR 条件で抽出する
      scope = scope.where('Division IN (?)', divisions)
      Rails.logger.debug("Filtering by Divisions: #{divisions.inspect}")
    end
  end

  # Major の処理
  if params[:major].present? && params[:major] != '未選択'
    # カンマで分割して配列に変換
    majors = params[:major].split(',').map(&:strip)
    scope = scope.where('major IN (?)', majors)
    Rails.logger.debug("Filtering by majors: #{majors.inspect}")
  else
    Rails.logger.debug("No major selected, no filtering applied.")
  end

  # Urbanicity の処理
  if params[:urbanicity].present?
    urbanicities = params[:urbanicity].split(',').map(&:strip)
    if urbanicities.any?
      scope = scope.where(urbanicity: urbanicities)
      Rails.logger.debug("Filtering by urbanicities: #{urbanicities.inspect}")
    end
  end

# Graduation Rate の処理
if params[:graduation_rate].present? && params[:graduation_rate] != '指定しない'
  # パラメータから数値を抽出 (例: "50%~" → 50)
  if params[:graduation_rate].match?(/(\d+)%~/)
    min_rate = params[:graduation_rate].match(/(\d+)%~/)[1].to_f / 100.0
    scope = scope.where('graduation_rate >= ?', min_rate)
    Rails.logger.debug("Filtering by graduation rate >= #{min_rate}")
  end
end




  # ページネーションの追加
  page = params[:page] || 1
  per_page = params[:per_page] || 20
  
  @results = scope.page(page).per(per_page)
  @total_count = scope.count
  Rails.logger.debug("Generated SQL Query: #{@results.to_sql}")
  end

  def show
    @college = Condition.find_by(slug: params[:id]) || Condition.find_by(id: params[:id])
  Rails.logger.debug("College found: #{@college.inspect}")
    if @college
      render :show
    else
      redirect_to :fallback_page
    end
  end

  def fallback_page
    render plain: "申し訳ありませんが、この大学の詳細ページはまだ作成されていません。", status: :not_found
  end

  private

    #tuitionの追加処理
    def parse_tuition_range(tuition_param)
    return nil unless tuition_param.present?
  
    # ユーザーが選んだパラメータが「~$9999」形式の場合
    if tuition_param.match?(/^~\$\d+(?:,\d{3})*$/)
      max_value = tuition_param.gsub('~$', '').gsub(',', '').to_i
      [0, max_value]  # 0 から最大金額まで
  
    # ユーザーが選んだパラメータが「$3000~$9999」形式の場合
    elsif tuition_param.match?(/^\$\d+(?:,\d{3})*~\$\d+(?:,\d{3})*$/)
      range = tuition_param.scan(/\d+(?:,\d{3})*/).map { |num| num.gsub(',', '').to_i }
      range.minmax  # 範囲を最小値と最大値として返す
  
    # ユーザーが選んだパラメータが「$3000~」形式の場合
    elsif tuition_param.match?(/^\$\d+(?:,\d{3})*~$/)
      min_value = tuition_param.gsub('$', '').gsub(',', '').to_i
      # 無制限を最大値（例えば999999）に変換
      [min_value, 999_999]  # 最小金額から最大金額まで
  
    else
      nil
    end
  end

  #studentsの追加処理
  def parse_students_range(students_param)
    Rails.logger.debug("Students param received: #{students_param}")
  
    # 学生数範囲の日本語を対応する数字に変換
    students_param = students_param.gsub("小規模(~2999人)", "0~2999")
                                   .gsub("中規模(3000人~9999人)", "3000~9999")
                                   .gsub("大規模(10,000人~29,999人)", "10000~29999")
                                   .gsub("超大規模(30,000人~)", "30000~")
  
    return nil unless students_param.present?
  
    ranges = []
  
    students_param.split(',').each do |range_str|
      Rails.logger.debug("Processing range string: #{range_str}")
  
      # 範囲の解析
      if range_str.match?(/(\d+)(~?)(\d*)/)
        match_data = range_str.match(/(\d+)(~?)(\d*)/)
        min_value = match_data[1].to_i
        max_value = match_data[3].present? ? match_data[3].to_i : nil
  
        # "小規模" (0~2999) と "超大規模" (30000~) の特殊ケース
        if min_value == 0 && max_value.nil?
          ranges << [0, 2999]  # 0〜2999
        elsif min_value == 30000 && max_value.nil?
          ranges << [30000, 1000000]  # 30000〜非常に大きな値（1000000 など）
        elsif max_value
          ranges << [min_value, max_value]
        else
          ranges << [min_value, min_value]
        end
  
        Rails.logger.debug("Parsed range: #{ranges.inspect}")
      else
        Rails.logger.debug("No match for students range: #{range_str}")
      end
    end
  
    Rails.logger.debug("Final ranges: #{ranges.inspect}")
    return ranges.empty? ? nil : ranges
  end


# Graduation Rate の範囲をパースする
def parse_graduation_rate_range(param)
  return nil unless param.present?

  # 例: "50~60" → [0.5, 0.6]
  if param.match?(/^(\d{1,2}|100)~(\d{1,2}|100)$/)
    range = param.split('~').map(&:to_f).map { |v| v / 100.0 }
    return range.minmax
  elsif param.match?(/^~(\d{1,2}|100)$/)
    max = param.gsub('~', '').to_f / 100.0
    return [0.0, max]
  elsif param.match?(/^(\d{1,2}|100)~$/)
    min = param.gsub('~', '').to_f / 100.0
    return [min, 1.0]
  end

  nil
end



  # GPAの範囲を解析するメソッド
  def parse_gpa_range(gpa_param)
    return nil unless gpa_param.present?
  
    # パラメータが「0.0~2.49」のような形式の場合
    if gpa_param.match?(/^(\d+(\.\d{1,2})?)~(\d+(\.\d{1,2})?)$/)
      range = gpa_param.scan(/(\d+(\.\d{1,2})?)/).map(&:first).map(&:to_f)
      min_gpa, max_gpa = range.minmax
      return nil if min_gpa < 0 || max_gpa > 5.0 # 有効な範囲は 0.0~5.0
      [min_gpa, max_gpa]
  
    # パラメータが「~2.49」のような形式の場合
    elsif gpa_param.match?(/^~(\d+(\.\d{1,2})?)$/)
      max_value = gpa_param.scan(/(\d+(\.\d{1,2})?)/).first.first.to_f
      return nil if max_value > 5.0 # 最大値が5.0を超える場合は無効
      [0.0, max_value]
  
    # パラメータが「2.49~」のような形式の場合
    elsif gpa_param.match?(/^(\d+(\.\d{1,2})?)~$/)
      min_value = gpa_param.scan(/(\d+(\.\d{1,2})?)/).first.first.to_f
      return nil if min_value < 0 || min_value > 5.0 # 最小値が無効な場合
      [min_value, 5.0] # 最大値を5.0に設定
  
    else
      nil
    end
  end


  def ohio_northern_university
    render 'ohio_northern_university'
  end
  
  def ohio_state_university
    render 'ohio_state_university'
  end

  def florida_state_university
    render 'florida_state_university'
  end

  def alabama_state_university
    render 'alabama_state_university'
  end





end