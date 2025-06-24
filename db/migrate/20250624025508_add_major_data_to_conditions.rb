class AddMajorDataToConditions < ActiveRecord::Migration[8.0]
  def change
    # 主要な専攻分野の学位授与割合を保存するカラムを追加
    add_column :conditions, :pcip_agriculture, :decimal, precision: 5, scale: 4  # 農業・農学
    add_column :conditions, :pcip_natural_resources, :decimal, precision: 5, scale: 4  # 天然資源・環境科学
    add_column :conditions, :pcip_communication, :decimal, precision: 5, scale: 4  # コミュニケーション学
    add_column :conditions, :pcip_computer_science, :decimal, precision: 5, scale: 4  # コンピューターサイエンス
    add_column :conditions, :pcip_education, :decimal, precision: 5, scale: 4  # 教育学
    add_column :conditions, :pcip_engineering, :decimal, precision: 5, scale: 4  # 工学
    add_column :conditions, :pcip_foreign_languages, :decimal, precision: 5, scale: 4  # 外国語・文学
    add_column :conditions, :pcip_english, :decimal, precision: 5, scale: 4  # 英語・文学
    add_column :conditions, :pcip_biology, :decimal, precision: 5, scale: 4  # 生物学
    add_column :conditions, :pcip_mathematics, :decimal, precision: 5, scale: 4  # 数学・統計学
    add_column :conditions, :pcip_psychology, :decimal, precision: 5, scale: 4  # 心理学
    add_column :conditions, :pcip_sociology, :decimal, precision: 5, scale: 4  # 社会学
    add_column :conditions, :pcip_social_sciences, :decimal, precision: 5, scale: 4  # 社会科学
    add_column :conditions, :pcip_visual_arts, :decimal, precision: 5, scale: 4  # 視覚・舞台芸術
    add_column :conditions, :pcip_business, :decimal, precision: 5, scale: 4  # 経営学
    add_column :conditions, :pcip_health_professions, :decimal, precision: 5, scale: 4  # 健康・医療
    add_column :conditions, :pcip_history, :decimal, precision: 5, scale: 4  # 歴史学
    add_column :conditions, :pcip_philosophy, :decimal, precision: 5, scale: 4  # 哲学・宗教学
    add_column :conditions, :pcip_physical_sciences, :decimal, precision: 5, scale: 4  # 物理科学
    add_column :conditions, :pcip_law, :decimal, precision: 5, scale: 4  # 法学・刑事司法
  end
end
