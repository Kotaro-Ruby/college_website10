require 'httparty'
require 'json'
require 'csv'

API_KEY = "4Wf4lWdWNe4Iyc8BtZ6cfBGdmuIvUVv4osDskvIw"
BASE_URL = "https://api.data.gov/ed/collegescorecard/v1/schools"
PER_PAGE = 100
MAX_PAGES = 200

URBANICITY_MAP = {
  11 => "City: Large", 12 => "City: Midsize", 13 => "City: Small",
  21 => "Suburb: Large", 22 => "Suburb: Midsize", 23 => "Suburb: Small",
  31 => "Town: Fringe", 32 => "Town: Distant", 33 => "Town: Remote",
  41 => "Rural: Fringe", 42 => "Rural: Distant", 43 => "Rural: Remote"
}

FIELDS = %w[
  school.name school.state latest.student.size school.ownership
  latest.admissions.admission_rate.overall school.city school.address
  school.zip school.locale school.school_url school.degrees_awarded.highest
  latest.completion.rate_suppressed.overall latest.cost.tuition.out_of_state
  latest.programs.cip_4_digit latest.student.student_faculty_ratio
  latest.student.demographics.race_ethnicity
  latest.admissions.sat_scores.average.overall
  latest.admissions.act_scores.midpoint.composite
].join(",")

CSV.open("all_colleges_export.csv", "w", write_headers: true, headers: [
  "college", "state", "students", "privateorpublic", "acceptance_rate",
  "city", "address", "zip", "urbanicity", "website", "school_type",
  "graduation_rate", "GPA", "Division", "tuition", "fields_of_study_json",
  "student_faculty_ratio", "race_ethnicity_json", "sat_score", "act_score"
]) do |csv|
  1.upto(MAX_PAGES) do |page|
    puts "📄 Fetching page #{page}..."

    res = HTTParty.get(BASE_URL, query: {
      api_key: API_KEY,
      fields: FIELDS,
      per_page: PER_PAGE,
      page: page,
      "school.operating" => 1
    })

    data = JSON.parse(res.body)
    break if data["results"].nil? || data["results"].empty?

    data["results"].each do |r|
      name = r["school.name"]
      state = r["school.state"]
      students = r["latest.student.size"]
      ownership = case r["school.ownership"]
                  when 1 then "Public"
                  when 2 then "Private"
                  when 3 then "For-Profit"
                  else "Unknown"
                  end
      acceptance_rate = r["latest.admissions.admission_rate.overall"]
      city = r["school.city"]
      address = r["school.address"]
      zip = r["school.zip"]
      urbanicity = URBANICITY_MAP[r["school.locale"]] || "Unknown"
      website = r["school.school_url"]
      school_type = case r["school.degrees_awarded.highest"]
                    when 2 then "2-Year"
                    when 3, 4 then "4-Year"
                    else "Unknown"
                    end
      graduation_rate = r["latest.completion.rate_suppressed.overall"]
      gpa = "N/A"
      division = "N/A"
      tuition = r["latest.cost.tuition.out_of_state"]
      fields_json = r["latest.programs.cip_4_digit"]&.to_json
      faculty_ratio = r["latest.student.student_faculty_ratio"]
      race_json = r["latest.student.demographics.race_ethnicity"]&.to_json
      sat_score = r.dig("latest.admissions.sat_scores", "average", "overall")
      act_score = r.dig("latest.admissions.act_scores", "midpoint", "composite")

      csv << [
        name, state, students, ownership, acceptance_rate, city, address, zip,
        urbanicity, website, school_type, graduation_rate, gpa, division,
        tuition, fields_json, faculty_ratio, race_json, sat_score, act_score
      ]
    end

    break if data["results"].size < PER_PAGE
    sleep 0.3
  end
end

puts "✅ データ保存完了 → all_colleges_export.csv"
