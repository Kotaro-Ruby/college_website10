require 'roo'

# Excelファイルのパスを設定
file_path = "C:/Users/kotar/Downloads/college_data_revised5_18_25_5th.xlsx"

# Excelファイルを読み込む
spreadsheet = Roo::Spreadsheet.open(file_path)

# 最初のシートを選択
sheet = spreadsheet.sheet(0)

# ヘッダーを取得（最初の行をヘッダーとして使用）
header = sheet.row(1).map(&:strip)

# 特別処理対象のキー
keep_na_fields = ["graduation_rate", "acceptance_rate", "students"]
null_fields = ["GPA", "tuition", "Division"]

# データ行を処理
(2..sheet.last_row).each do |i|
  row = Hash[[header, sheet.row(i)].transpose]

  row.each do |key, value|
    value_str = value.to_s.strip
    value_up = value_str.upcase

    if keep_na_fields.include?(key)
      row[key] = "N/A" if value_str == ""
    elsif null_fields.include?(key)
      row[key] = nil if value_str == "" || value_up == "N/A"
    else
      row[key] = nil if value_str == "" || value_up == "N/A"
    end
  end

  # デバッグ: GPAを出力して確認（必要なければ消してOK）
  puts "Row #{i} GPA value: #{row["GPA"].inspect}"

  # DBに保存
  Condition.find_or_create_by(college: row["college"]) do |condition|
    condition.state = row["state"]
    condition.tuition = row["tuition"]
    condition.students = row["students"]
    condition.major = row["major"]
    condition.GPA = row["GPA"]
    condition.privateorpublic = row["privateorpublic"]
    condition.Division = row["Division"]
    condition.city = row["city"]
    condition.address = row["address"]
    condition.zip = row["zip"]
    condition.urbanicity = row["urbanicity"]
    condition.website = row["website"]
    condition.school_type = row["school_type"]
    condition.graduation_rate = row["graduation_rate"]
    condition.acceptance_rate = row["acceptance_rate"]
  end
end

puts "✅ Data import complete!"




