require 'net/http'
require 'json'
require 'csv'
require 'uri'

class ExportCollegeDataToCSV
  API_KEY = 'R8tByl5fHaRhfqN0fXmUwHWbVbVrUnG3d4Kmktlf'
  BASE_URL = 'https://api.data.gov/ed/collegescorecard/v1/schools'
  FIELDS = 'school.name,school.state,latest.student.size,school.ownership,latest.admissions.admission_rate.overall,school.city,school.address,school.zip,school.locale,school.school_url,school.degrees_awarded.predominant,latest.completion.rate_suppressed.overall,school.degrees_awarded.highest'
  PER_PAGE = 100

  URBANICITY_MAP = {
    11 => "City: Large",
    12 => "City: Midsize",
    13 => "City: Small",
    21 => "Suburb: Large",
    22 => "Suburb: Midsize",
    23 => "Suburb: Small",
    31 => "Town: Fringe",
    32 => "Town: Distant",
    33 => "Town: Remote",
    41 => "Rural: Fringe",
    42 => "Rural: Distant",
    43 => "Rural: Remote"
  }

  def self.export_all(file_path = "college_data.csv")
    page = 0
    total_pages = 1

    CSV.open(file_path, "w") do |csv|
      csv << [
        "college",
        "state",
        "students",
        "privateorpublic",
        "acceptance_rate",
        "city",
        "address",
        "zip",
        "urbanicity",
        "website",
        "school_type",
        "graduation_rate"
      ]

      while page < total_pages
        page += 1
        puts "📄 Fetching page #{page}..."

        uri = URI(BASE_URL)
        uri.query = URI.encode_www_form({
          "api_key" => API_KEY,
          "fields" => FIELDS,
          "per_page" => PER_PAGE,
          "page" => page,
          "school.operating" => 1
        })

        res = Net::HTTP.get_response(uri)
        break unless res.is_a?(Net::HTTPSuccess)

        json = JSON.parse(res.body)
        results = json["results"]
        total_pages = (json["metadata"]["total"].to_f / PER_PAGE).ceil

        results.each do |info|
          ownership = case info["school.ownership"]
                      when 1 then "Public"
                      when 2 then "Private"
                      when 3 then "For-Profit"
                      else "Unknown"
                      end

          address = info["school.address"] || "N/A"
          zip = info["school.zip"] || "N/A"

          # urbanicity
          urbanicity_code = info["school.locale"]
          urbanicity = URBANICITY_MAP[urbanicity_code] || "Unknown"

          # website
          website = info["school.school_url"] || "N/A"

          # school type (based on highest degree awarded)
          highest_degree = info["school.degrees_awarded.highest"]
          school_type = case highest_degree
                        when 2 then "2-Year"
                        when 3, 4 then "4-Year"
                        else "Unknown"
                        end

          # graduation_rate
          graduation_rate = info["latest.completion.rate_suppressed.overall"]

          csv << [
            info["school.name"],
            info["school.state"],
            info["latest.student.size"],
            ownership,
            info["latest.admissions.admission_rate.overall"],
            info["school.city"],
            address,
            zip,
            urbanicity,
            website,
            school_type,
            graduation_rate
          ]
        end
      end
    end

    puts "✅ Exported all data to #{file_path}"
  end
end
