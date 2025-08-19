class ExternalDataService
  # SportRadar API (有料)
  # https://developer.sportradar.com/

  # The Sports DB (一部無料)
  # https://www.thesportsdb.com/api.php

  # College Football Data API (無料)
  # https://collegefootballdata.com/

  def self.fetch_ncaa_data(college_name)
    # APIキーを環境変数から取得
    api_key = ENV["SPORTS_API_KEY"]

    # ここにAPI呼び出しロジックを実装
    # 例: College Football Data APIを使用
    uri = URI("https://api.collegefootballdata.com/teams")
    response = Net::HTTP.get_response(uri)

    if response.code == "200"
      teams = JSON.parse(response.body)
      team = teams.find { |t| t["school"].downcase.include?(college_name.downcase) }

      if team
        {
          division: team["division"],
          conference: team["conference"],
          mascot: team["mascot"],
          colors: team["colors"]
        }
      end
    end
  rescue => e
    Rails.logger.error "Error fetching NCAA data: #{e.message}"
    nil
  end
end
