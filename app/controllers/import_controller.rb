class ImportController < ApplicationController
    def conditions
      load Rails.root.join('db', 'scripts', 'import_conditions.rb')
      render plain: "✅ 本番データ取り込み完了！"
    end
  end
  