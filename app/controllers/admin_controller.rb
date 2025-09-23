
class AdminController < ApplicationController
  # ⚠️ 警告: このコントローラーは非推奨です ⚠️
  # 新しい管理者認証システムが実装されました。
  # 管理者はadmin/setupまたはadmin/loginから新システムを利用してください。
  # このファイルは将来的に削除される予定です。

  def setup_data
    # セキュリティのため、特定のパラメータでのみ実行
    if params[:secret] != "setup123"
      render plain: "アクセス拒否"
      return
    end

    begin
      result = []
      result << "=== 本番用データセットアップ開始 ==="

      # 圧縮データがある場合はそれを使用
      compressed_file = Rails.root.join("db", "college_data_compressed.json.gz")
      if File.exist?(compressed_file)
        result << "圧縮データファイルが見つかりました。バルクインポートを実行します..."

        # バルクインポートを実行
        require "zlib"
        compressed_data = File.read(compressed_file)
        json_data = Zlib::Inflate.inflate(compressed_data)
        data = JSON.parse(json_data)

        colleges_data = data["data"]
        imported_count = 0

        colleges_data.each do |college_data|
          full_data = {
            college: college_data["c"],
            state: college_data["s"],
            tuition: college_data["t"],
            students: college_data["st"],
            privateorpublic: college_data["p"],
            GPA: college_data["g"],
            acceptance_rate: college_data["a"],
            graduation_rate: college_data["gr"],
            city: college_data["ci"],
            Division: college_data["d"],
            comment: college_data["co"]
          }

          unless Condition.find_by(college: full_data[:college])
            Condition.create!(full_data)
            imported_count += 1
          end
        end

        result << "✓ #{imported_count}校をインポートしました"
      end

      # 本番用セットアップタスクを実行
      result << "本番用データセットアップタスクを実行中..."

      # 環境変数を設定してタスクを実行
      ENV["SKIP_DETAILED_PROGRAMS"] = "true"

      # setup_production_fastタスクを実行
      start_time = Time.current
      Rake::Task["college_data:setup_production_fast"].invoke
      end_time = Time.current

      duration = ((end_time - start_time) / 60).round(1)

      # 最終統計
      total_colleges = Condition.count
      colleges_with_comments = Condition.where.not(comment: [ nil, "" ]).count
      colleges_with_tuition = Condition.where.not(tuition: [ nil, 0 ]).count
      colleges_with_majors = Condition.where("pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0").count

      result << ""
      result << "=== セットアップ完了 ==="
      result << "実行時間: #{duration}分"
      result << "総大学数: #{total_colleges}"
      result << "コメント付き: #{colleges_with_comments} (#{(colleges_with_comments.to_f / total_colleges * 100).round(1)}%)"
      result << "授業料データ付き: #{colleges_with_tuition} (#{(colleges_with_tuition.to_f / total_colleges * 100).round(1)}%)"
      result << "専攻データ付き: #{colleges_with_majors} (#{(colleges_with_majors.to_f / total_colleges * 100).round(1)}%)"
      result << "ブラウザでページを再読み込みして確認してください。"
      result << "セットアップ完了後は、このadmin_controller.rbとルートを削除してください。"

      render plain: result.join("\n")

    rescue => e
      render plain: "エラーが発生しました: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end

  def status
    if params[:secret] != "setup123"
      render plain: "アクセス拒否"
      return
    end

    total = Condition.count
    comments = Condition.where.not(comment: [ nil, "" ]).count
    tuition = Condition.where.not(tuition: [ nil, 0 ]).count
    majors = Condition.where("pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0").count

    result = []
    result << "=== データベース状況 ==="
    result << "総大学数: #{total}"
    result << "コメント付き: #{comments} (#{(comments.to_f / total * 100).round(1)}%)" if total > 0
    result << "授業料データ付き: #{tuition} (#{(tuition.to_f / total * 100).round(1)}%)" if total > 0
    result << "専攻データ付き: #{majors} (#{(majors.to_f / total * 100).round(1)}%)" if total > 0
    result << ""
    result << "API Key設定: #{ENV['COLLEGE_SCORECARD_API_KEY'] ? '設定済み' : '未設定'}"

    # 圧縮データファイルの存在確認
    compressed_file = Rails.root.join("db", "college_data_compressed.json.gz")
    if File.exist?(compressed_file)
      file_size = File.size(compressed_file) / 1024.0
      result << "圧縮データファイル: 存在 (#{file_size.round(1)} KB)"
    else
      result << "圧縮データファイル: なし"
    end

    # 詳細プログラム数
    detailed_programs = DetailedProgram.count rescue 0
    result << "詳細プログラム数: #{detailed_programs}"

    # 利用可能なRakeタスク
    result << ""
    result << "=== 利用可能なタスク ==="
    result << "college_data:setup_production - 完全セットアップ（時間がかかる）"
    result << "college_data:setup_production_fast - 高速セットアップ（詳細プログラムをスキップ）"
    result << "college_data:add_comments - コメントのみ追加"
    result << "college_data:import_major_data - 専攻データのみ追加"

    render plain: result.join("\n")
  end

  def import_bulk
    if params[:secret] != "setup123"
      render plain: "アクセス拒否"
      return
    end

    begin
      require "zlib"

      result = []
      result << "=== バルクインポート開始 ==="

      compressed_file = Rails.root.join("db", "college_data_compressed.json.gz")

      unless File.exist?(compressed_file)
        result << "エラー: 圧縮データファイルが見つかりません"
        render plain: result.join("\n")
        return
      end

      # 現在のデータ数
      current_count = Condition.count
      result << "現在のデータ数: #{current_count}"

      # 圧縮ファイルを展開してインポート
      result << "圧縮ファイルを読み込み中..."

      compressed_data = File.read(compressed_file)
      json_data = Zlib::Inflate.inflate(compressed_data)
      data = JSON.parse(json_data)

      colleges_data = data["data"]
      total_count = colleges_data.size

      result << "インポート対象: #{total_count}校"
      result << "エクスポート日時: #{data['export_date']}"
      result << ""
      result << "インポート開始..."

      imported_count = 0
      updated_count = 0
      error_count = 0

      colleges_data.each_with_index do |college_data, index|
        begin
          # 短縮フィールド名を元に戻す
          full_data = {
            college: college_data["c"],
            state: college_data["s"],
            tuition: college_data["t"],
            students: college_data["st"],
            privateorpublic: college_data["p"],
            GPA: college_data["g"],
            acceptance_rate: college_data["a"],
            graduation_rate: college_data["gr"],
            city: college_data["ci"],
            Division: college_data["d"],
            comment: college_data["co"]
          }

          # 既存のレコードを確認
          existing_college = Condition.find_by(college: full_data[:college])

          if existing_college
            # 更新
            existing_college.update!(full_data)
            updated_count += 1
          else
            # 新規作成
            Condition.create!(full_data)
            imported_count += 1
          end

          if (index + 1) % 500 == 0
            result << "進捗: #{index + 1}/#{total_count} (#{((index + 1).to_f / total_count * 100).round(1)}%)"
          end

        rescue => e
          error_count += 1
          result << "エラー: #{college_data['c']} - #{e.message}" if error_count <= 10
        end
      end

      final_count = Condition.count

      result << ""
      result << "=== インポート完了 ==="
      result << "新規作成: #{imported_count}校"
      result << "更新: #{updated_count}校"
      result << "エラー: #{error_count}校"
      result << "最終データ数: #{final_count}校"
      result << ""
      result << "ページを再読み込みして確認してください。"

      render plain: result.join("\n")

    rescue => e
      render plain: "バルクインポートエラーが発生しました: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end
end
