class CreateDetailedPrograms < ActiveRecord::Migration[8.0]
  def change
    create_table :detailed_programs do |t|
      t.references :condition, null: false, foreign_key: true
      t.string :cip_code, null: false              # CIPコード (例: "2601")
      t.string :program_title, null: false         # 専攻名 (例: "Biology, General.")
      t.string :program_title_jp                   # 日本語専攻名 (例: "生物学（一般）")
      t.integer :credential_level                  # 学位レベル (1=Certificate, 2=Associate, 3=Bachelor, 4=Master, 5=Doctoral)
      t.string :credential_title                   # 学位タイトル (例: "Bachelor's Degree")
      t.integer :graduates_count                   # 卒業者数
      t.string :major_category                     # 専攻カテゴリー (例: "Biology", "Engineering")
      t.text :description                          # 専攻の説明

      t.timestamps
    end

    add_index :detailed_programs, [ :condition_id, :cip_code ], unique: true
    add_index :detailed_programs, :cip_code
    add_index :detailed_programs, :major_category
    add_index :detailed_programs, :credential_level
  end
end
