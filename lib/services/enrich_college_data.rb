require 'roo'
require 'csv'
require 'json'
require 'net/http'
require 'uri'

API_KEY = 'R8tByl5fHaRhfqN0fXmUwHWbVbVrUnG3d4Kmktlf'
BASE_URL = 'https://api.data.gov/ed/collegescorecard/v1/schools'

# データ処理用スクリプト - 本番環境では実行されません
return unless Rails.env.development?

INPUT_XLSX_PATH = Rails.root.join('data', 'college_data_revised5_18_25_6th.xlsx')
OUTPUT_CSV_PATH = Rails.root.join('data', 'college_data_enriched.csv')

PROGRAM_FIELDS = %w[
  agriculture architecture area_ethnic_cultural_gender biological
  business_marketing communication computer construction
  education engineering english family_consumer_science
  foreign_language health history legal library mathematics
  mechanic_repair_technology military multidiscipline
  natural_resources parks_recreation_fitness personal_culinary
  philosophy_religious physical_science precision_production
  psychology public_administration_social_service
  security_law_enforcement social_science theology_religious_vocation
  transportation visual_performing
]

FIELDS = [
  'latest.student.faculty_ratio',
  'latest.student.demographics.race_ethnicity.white',
  'latest.student.demographics.race_ethnicity.black',
  'latest.student.demographics.race_ethnicity.hispanic',
  'latest.student.demographics.race_ethnicity.asian',
  'latest.student.demographics.race_ethnicity.aian',
  'latest.student.demographics.race_ethnicity.nhpi',
  'latest.student.demographics.race_ethnicity.two_or_more',
  'latest.admissions.sat_scores.average.overall',
  'latest.admissions.act_scores.midpoint.cumulative',
  'latest.admissions.act_scores.midpoint.math',
  'latest.admissions.act_scores.midpoint.english',
  'latest.cost.tuition.out_of_state'
] + PROGRAM_FIELDS.map { |f| "2018.academics.program_percentage.#{f}" }

puts "📖 Excelファイル読み込み中..."

xlsx = Roo::Spreadsheet.open(INPUT_XLSX_PATH)
sheet = xlsx.sheet(0)
headers = sheet.row(1).map(&:to_s)

CSV.open(OUTPUT_CSV_PATH, 'w') do |csv|
  csv << headers

  (2..sheet.last_row).each_with_index do |i, idx|
    row = Hash[headers.zip(sheet.row(i))]
    college = row['college']&.strip
    student_count = row['students'].to_i

    if college.to_s.empty? || student_count.zero?
      puts "⚠️ (#{idx + 1}) #{college} の検索に必要な情報が不足しています"
      csv << row.values
      next
    end

    needs_update = row['student_faculty_ratio'].to_s.strip.empty? ||
                   row['race_ethnicity_json'].to_s.strip.empty? ||
                   row['fields_of_study_json'].to_s.strip.empty? ||
                   row['sat_score'].to_s.strip.empty? ||
                   row['act_score'].to_s.strip.empty? ||
                   row['tuition'].to_s.strip.empty?

    unless needs_update
      csv << row.values
      next
    end

    print "🔍 (#{idx + 1}) #{college} を検索中..."

    range = [ [student_count - 50, 0].max, student_count + 50 ].join("..")

    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form({
      'api_key' => API_KEY,
      'school.name' => college,
      'latest.student.size__range' => range,
      'per_page' => 1,
      'fields' => FIELDS.join(',')
    })

    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      result = JSON.parse(res.body)['results'].first
      if result
        row['student_faculty_ratio'] ||= result['latest.student.faculty_ratio']

        if row['race_ethnicity_json'].to_s.strip.empty?
          race_data = %w[white black hispanic asian aian nhpi two_or_more].map do |r|
            [r, result.dig("latest.student.demographics.race_ethnicity.#{r}")]
          end.to_h
          row['race_ethnicity_json'] = race_data.to_json
        end

        row['sat_score'] ||= result['latest.admissions.sat_scores.average.overall']

        if row['act_score'].to_s.strip.empty?
          act = {
            composite: result['latest.admissions.act_scores.midpoint.cumulative'],
            math: result['latest.admissions.act_scores.midpoint.math'],
            english: result['latest.admissions.act_scores.midpoint.english']
          }
          row['act_score'] = act.to_json
        end

        row['tuition'] ||= result['latest.cost.tuition.out_of_state']

        if row['fields_of_study_json'].to_s.strip.empty?
          field_data = PROGRAM_FIELDS.map do |f|
            [f, result["2018.academics.program_percentage.#{f}"]]
          end.to_h
          row['fields_of_study_json'] = field_data.to_json
        end
      else
        puts "❌ データ見つからず"
      end
    else
      puts "❌ APIエラー: #{res.code}"
    end

    csv << headers.map { |h| row[h] }
  end
end

puts "✅ 完了：#{OUTPUT_CSV_PATH} に保存しました。"
