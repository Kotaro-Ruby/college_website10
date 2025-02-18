require 'roo'

# Excelファイルのパスを設定
file_path = "C:/Users/kotar/Downloads/College_details_Arkansas.xlsx"

# Excelファイルを読み込む
spreadsheet = Roo::Spreadsheet.open(file_path)

# 最初のシートを選択
sheet = spreadsheet.sheet(0)

# ヘッダーを取得（最初の行をヘッダーとして使用）
header = sheet.row(1).map(&:strip) # 空白をトリム

# データ行を繰り返し処理
(2..sheet.last_row).each do |i|
  row = Hash[[header, sheet.row(i)].transpose] # ヘッダーとデータを結合

# GPAが'N/A'の場合、'N/A'を設定
row["GPA"] = nil if row["GPA"] == "N/A"

  # データをデバッグ出力（オプション）
  puts "Processing row #{i}: #{row.inspect}"

  # Conditionsテーブルにデータを追加
  Condition.find_or_create_by(college: row["college"]) do |condition|
    condition.state = row["state"]
    condition.tuition = row["tuition"]
    condition.students = row["students"]
    condition.major = row["major"]
    condition.GPA = row["GPA"]
    condition.privateorpublic = row["privateorpublic"]
    condition.Division = row["Division"]
  end
end

puts "Data import complete!"
