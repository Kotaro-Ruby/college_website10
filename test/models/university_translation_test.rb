require "test_helper"

class UniversityTranslationTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil university_translations(:osu_ja)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid translation with all required attributes" do
    translation = UniversityTranslation.new(
      condition: conditions(:womens_college),
      locale: "ja",
      name: "ウェルズリーカレッジ"
    )
    assert translation.valid?
  end

  test "invalid without locale" do
    translation = UniversityTranslation.new(
      condition: conditions(:harvard),
      name: "ハーバード大学"
    )
    assert_not translation.valid?
    assert_includes translation.errors[:locale], "can't be blank"
  end

  test "invalid without name" do
    translation = UniversityTranslation.new(
      condition: conditions(:harvard),
      locale: "ja"
    )
    assert_not translation.valid?
    assert_includes translation.errors[:name], "can't be blank"
  end

  test "invalid without condition" do
    translation = UniversityTranslation.new(
      locale: "ja",
      name: "テスト大学"
    )
    assert_not translation.valid?
  end

  test "invalid with duplicate locale for same condition" do
    existing = university_translations(:osu_ja)
    translation = UniversityTranslation.new(
      condition: existing.condition,
      locale: existing.locale,
      name: "別の名前"
    )
    assert_not translation.valid?
    assert_includes translation.errors[:locale], "has already been taken"
  end

  test "same locale can be used for different conditions" do
    translation1 = university_translations(:osu_ja)
    translation2 = UniversityTranslation.new(
      condition: conditions(:womens_college),
      locale: "ja",
      name: "ウェルズリーカレッジ"
    )
    assert translation2.valid?
  end

  # ===========================================
  # アソシエーションのテスト
  # ===========================================
  test "belongs to condition" do
    translation = university_translations(:osu_ja)
    assert_equal conditions(:state_university), translation.condition
  end

  # ===========================================
  # 作成・削除のテスト
  # ===========================================
  test "can create translation" do
    assert_difference "UniversityTranslation.count", 1 do
      UniversityTranslation.create!(
        condition: conditions(:community_college),
        locale: "ja",
        name: "マイアミデイドカレッジ"
      )
    end
  end

  test "can destroy translation" do
    translation = university_translations(:osu_ja)

    assert_difference "UniversityTranslation.count", -1 do
      translation.destroy
    end
  end

  test "destroying translation does not destroy condition" do
    translation = university_translations(:osu_ja)
    condition = translation.condition

    translation.destroy
    assert Condition.exists?(condition.id)
  end

  # ===========================================
  # 多言語対応のテスト
  # ===========================================
  test "can have multiple locales for same condition" do
    condition = conditions(:womens_college)

    UniversityTranslation.create!(condition: condition, locale: "ja", name: "ウェルズリーカレッジ")
    UniversityTranslation.create!(condition: condition, locale: "zh", name: "韦尔斯利学院")
    UniversityTranslation.create!(condition: condition, locale: "ko", name: "웰즐리 칼리지")

    assert_equal 3, condition.university_translations.count
  end
end
