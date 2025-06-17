# require 'net/http'
# require 'json'
# require 'csv'
# require 'uri'

# class ExportCollegeDataToCSV
#   API_KEY = 'R8tByl5fHaRhfqN0fXmUwHWbVbVrUnG3d4Kmktlf'
#   BASE_URL = 'https://api.data.gov/ed/collegescorecard/v1/schools'
#   FIELDS = 'school.name,school.state,latest.student.size,school.ownership,latest.admissions.admission_rate.overall,school.city,school.address,school.zip,school.locale,school.school_url,school.degrees_awarded.predominant,latest.completion.rate_suppressed.overall,school.degrees_awarded.highest'
#   PER_PAGE = 100

#   URBANICITY_MAP = {
#     11 => "City: Large",
#     12 => "City: Midsize",
#     13 => "City: Small",
#     21 => "Suburb: Large",
#     22 => "Suburb: Midsize",
#     23 => "Suburb: Small",
#     31 => "Town: Fringe",
#     32 => "Town: Distant",
#     33 => "Town: Remote",
#     41 => "Rural: Fringe",
#     42 => "Rural: Distant",
#     43 => "Rural: Remote"
#   }

#   def self.export_all(file_path = "college_data.csv")
#     page = 0
#     total_pages = 1

#     CSV.open(file_path, "w") do |csv|
#       csv << [
#         "college",
#         "state",
#         "students",
#         "privateorpublic",
#         "acceptance_rate",
#         "city",
#         "address",
#         "zip",
#         "urbanicity",
#         "website",
#         "school_type",
#         "graduation_rate"
#       ]

#       while page < total_pages
#         page += 1
#         puts "📄 Fetching page #{page}..."

#         uri = URI(BASE_URL)
#         uri.query = URI.encode_www_form({
#           "api_key" => API_KEY,
#           "fields" => FIELDS,
#           "per_page" => PER_PAGE,
#           "page" => page,
#           "school.operating" => 1
#         })

#         res = Net::HTTP.get_response(uri)
#         break unless res.is_a?(Net::HTTPSuccess)

#         json = JSON.parse(res.body)
#         results = json["results"]
#         total_pages = (json["metadata"]["total"].to_f / PER_PAGE).ceil

#         results.each do |info|
#           ownership = case info["school.ownership"]
#                       when 1 then "Public"
#                       when 2 then "Private"
#                       when 3 then "For-Profit"
#                       else "Unknown"
#                       end

#           address = info["school.address"] || "N/A"
#           zip = info["school.zip"] || "N/A"

#           # urbanicity
#           urbanicity_code = info["school.locale"]
#           urbanicity = URBANICITY_MAP[urbanicity_code] || "Unknown"

#           # website
#           website = info["school.school_url"] || "N/A"

#           # school type (based on highest degree awarded)
#           highest_degree = info["school.degrees_awarded.highest"]
#           school_type = case highest_degree
#                         when 2 then "2-Year"
#                         when 3, 4 then "4-Year"
#                         else "Unknown"
#                         end

#           # graduation_rate
#           graduation_rate = info["latest.completion.rate_suppressed.overall"]

#           csv << [
#             info["school.name"],
#             info["school.state"],
#             info["latest.student.size"],
#             ownership,
#             info["latest.admissions.admission_rate.overall"],
#             info["school.city"],
#             address,
#             zip,
#             urbanicity,
#             website,
#             school_type,
#             graduation_rate
#           ]
#         end
#       end
#     end

#     puts "✅ Exported all data to #{file_path}"
#   end
# end




require 'roo'
require 'rubyXL'
require 'httparty'
require 'json'

API_KEY = "4Wf4lWdWNe4Iyc8BtZ6cfBGdmuIvUVv4osDskvIw"
BASE_URL = "https://api.data.gov/ed/collegescorecard/v1/schools"

input_path = "C:/Users/kotar/Downloads/college_data_revised5_18_25_6th.xlsx"
workbook = RubyXL::Parser.parse(input_path)
worksheet = workbook[0]
sheet_roo = Roo::Excelx.new(input_path)
sheet_roo.default_sheet = sheet_roo.sheets[0]

# 列番号（0始まり）
COLLEGE_COL = 0
TUITION_COL = 13
FIELDS_JSON_COL = 14
FACULTY_RATIO_COL = 16
RACE_JSON_COL = 17
SAT_SCORE_COL = 18
ACT_SCORE_COL = 19

puts "📘 Excelファイル読み込み中..."

(2..sheet_roo.last_row).each do |i|
  original_name = sheet_roo.cell(i, COLLEGE_COL + 1).to_s.strip
  row_idx = i - 1

  # 検索用に整形（Inc, Campus, at ... など除去）
  name_for_search = original_name.gsub(/Inc|Campus| at .+$/, '').strip

  puts "🔍 (#{i - 1}) #{original_name} を検索中..."

  next if name_for_search.empty?

  query = {
    "api_key" => API_KEY,
    "school.search" => name_for_search,
    "fields" => [
      "school.name",
      "latest.cost.tuition.out_of_state",
      "latest.student.student_faculty_ratio",
      "latest.admissions.sat_scores.average.overall",
      "latest.admissions.act_scores.midpoint.composite",
      "latest.programs.cip_4_digit",
      "latest.student.demographics.race_ethnicity"
    ].join(",")
  }

  begin
    response = HTTParty.get(BASE_URL, query: query, timeout: 10)
    data = JSON.parse(response.body)
    results = data["results"]

    if results.nil? || results.empty?
      puts "❌ データ見つからず"
      next
    end

    # ベストマッチ（部分一致優先、なければ先頭）
    best_match = results.find { |r| r["school.name"]&.downcase&.include?(name_for_search.downcase) }
    best_match ||= results.first

    puts "🔗 マッチした大学名: #{best_match["school.name"]}"

    tuition = best_match.dig("latest", "cost", "tuition", "out_of_state")
    faculty_ratio = best_match.dig("latest", "student", "student_faculty_ratio")
    sat_score = best_match.dig("latest", "admissions", "sat_scores", "average", "overall")
    act_score = best_match.dig("latest", "admissions", "act_scores", "midpoint", "composite")
    fields_json = best_match["latest.programs.cip_4_digit"]&.to_json
    race_json = best_match.dig("latest", "student", "demographics", "race_ethnicity")&.to_json

    worksheet[row_idx][TUITION_COL]&.change_contents(tuition)
    worksheet[row_idx][FIELDS_JSON_COL]&.change_contents(fields_json)
    worksheet[row_idx][FACULTY_RATIO_COL]&.change_contents(faculty_ratio)
    worksheet[row_idx][RACE_JSON_COL]&.change_contents(race_json)
    worksheet[row_idx][SAT_SCORE_COL]&.change_contents(sat_score)
    worksheet[row_idx][ACT_SCORE_COL]&.change_contents(act_score)

    puts "✅ データ取得成功"

  rescue => e
    puts "⚠️ エラー: #{e.message}"
  end

  sleep 0.1  # API rate limit対応
end

# 保存
workbook.write(input_path)
puts "💾 保存完了: #{input_path}"
