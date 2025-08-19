class CreateAuCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :au_courses do |t|
      # 外部キー
      t.references :au_university, null: false, foreign_key: true
      
      # コース識別情報
      t.string :cricos_course_code, null: false      # CRICOS Course Code (固有ID)
      t.string :course_name, null: false              # コース名
      t.string :vet_national_code                     # VET National Code
      
      # 学位レベル
      t.string :course_level                          # Bachelor Degree, Masters, etc.
      t.boolean :dual_qualification, default: false   # 複数学位取得可能か
      t.boolean :foundation_studies, default: false   # ファウンデーションコースか
      
      # 専攻分野（最大3つまで保存）
      t.string :field_of_education_broad              # 大分類
      t.string :field_of_education_narrow             # 中分類  
      t.string :field_of_education_detailed           # 詳細分類
      
      # 期間
      t.integer :duration_weeks                       # 期間（週）
      t.decimal :duration_years                       # 期間（年）計算値
      
      # 実習要件
      t.boolean :work_component, default: false       # 実習あり
      t.decimal :work_component_hours_per_week        # 週あたり実習時間
      t.integer :work_component_weeks                 # 実習期間（週）
      t.integer :work_component_total_hours           # 実習総時間
      
      # 言語
      t.string :course_language, default: 'English'   # 授業言語
      
      # 費用
      t.decimal :tuition_fee                          # 授業料（全期間）
      t.decimal :non_tuition_fee                      # その他費用
      t.decimal :estimated_total_cost                 # 推定総費用
      t.decimal :annual_tuition_fee                   # 年間授業料（計算値）
      
      # ステータス
      t.boolean :expired, default: false              # 期限切れ
      t.boolean :active, default: true                # アクティブフラグ
      
      t.timestamps
    end
    
    # インデックスの追加
    add_index :au_courses, :cricos_course_code, unique: true
    add_index :au_courses, :course_level
    add_index :au_courses, :field_of_education_broad
    add_index :au_courses, :annual_tuition_fee
    add_index :au_courses, :duration_weeks
    add_index :au_courses, [:au_university_id, :course_level]
    add_index :au_courses, [:au_university_id, :active]
  end
end