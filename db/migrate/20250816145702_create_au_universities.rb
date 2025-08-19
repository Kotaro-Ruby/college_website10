class CreateAuUniversities < ActiveRecord::Migration[8.0]
  def change
    create_table :au_universities do |t|
      # 基本情報
      t.string :name, null: false                    # 大学名
      t.string :cricos_provider_code, null: false    # CRICOS Provider Code (固有ID)
      t.string :trading_name                         # 通称・別名
      t.string :institution_type                     # Government/Private
      t.integer :institution_capacity                # 留学生受入可能数

      # 所在地情報
      t.string :city
      t.string :state                                # NSW, VIC, QLD等
      t.string :postcode
      t.text :postal_address                          # 完全な住所

      # ウェブサイト
      t.string :website

      # コース統計情報（集計値を保存）
      t.integer :total_courses_count, default: 0     # 総コース数
      t.integer :bachelor_courses_count, default: 0  # 学士コース数
      t.integer :masters_courses_count, default: 0   # 修士コース数
      t.integer :doctoral_courses_count, default: 0  # 博士コース数

      # 授業料範囲（年間）
      t.decimal :min_annual_tuition                  # 最低年間授業料
      t.decimal :max_annual_tuition                  # 最高年間授業料
      t.decimal :avg_annual_tuition                  # 平均年間授業料

      # 人気分野（TOP3を保存、カンマ区切りで保存）
      t.string :popular_fields                       # 人気の専攻分野リスト（カンマ区切り）

      # ランキング情報（後で追加可能）
      t.integer :world_ranking                       # 世界ランキング
      t.integer :domestic_ranking                    # 国内ランキング

      # SEO用
      t.string :slug                                 # URLスラッグ
      t.text :description                            # 大学の説明文

      # 管理用
      t.boolean :active, default: true               # 表示/非表示フラグ
      t.json :comprehensive_data                     # その他の詳細データをJSON形式で保存

      t.timestamps
    end

    # インデックスの追加
    add_index :au_universities, :cricos_provider_code, unique: true
    add_index :au_universities, :slug, unique: true
    add_index :au_universities, :name
    add_index :au_universities, :state
    add_index :au_universities, :active
    add_index :au_universities, :world_ranking
    add_index :au_universities, :avg_annual_tuition
  end
end
