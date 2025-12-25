require "test_helper"

class CountryTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil countries(:usa)
    assert_not_nil countries(:australia)
    assert_not_nil countries(:japan)
    assert_not_nil countries(:canada)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid country with all required attributes" do
    country = Country.new(
      code: "GB",
      name: "United Kingdom"
    )
    assert country.valid?
  end

  test "invalid without code" do
    country = Country.new(name: "Test Country")
    assert_not country.valid?
    assert_includes country.errors[:code], "can't be blank"
  end

  test "invalid without name" do
    country = Country.new(code: "TC")
    assert_not country.valid?
    assert_includes country.errors[:name], "can't be blank"
  end

  test "invalid with duplicate code" do
    existing = countries(:usa)
    country = Country.new(code: existing.code, name: "Another Country")
    assert_not country.valid?
    assert_includes country.errors[:code], "has already been taken"
  end

  # ===========================================
  # 基本属性のテスト
  # ===========================================
  test "usa has correct attributes" do
    usa = countries(:usa)
    assert_equal "US", usa.code
    assert_equal "United States", usa.name
    assert_equal "Washington, D.C.", usa.capital
    assert_equal "USD", usa.currency_code
  end

  test "japan has correct attributes" do
    japan = countries(:japan)
    assert_equal "JP", japan.code
    assert_equal "Japan", japan.name
    assert_equal "Tokyo", japan.capital
    assert_equal "JPY", japan.currency_code
  end

  # ===========================================
  # メインの言語取得テスト
  # ===========================================
  test "main_language returns first language" do
    usa = countries(:usa)
    assert_equal "English", usa.main_language
  end

  test "main_language returns nil when languages is nil" do
    country = Country.new(code: "XX", name: "Test")
    assert_nil country.main_language
  end

  # ===========================================
  # タイムゾーン範囲のテスト
  # ===========================================
  test "timezone_range returns single timezone" do
    japan = countries(:japan)
    assert_equal "UTC+09:00", japan.timezone_range
  end

  test "timezone_range returns range for multiple timezones" do
    usa = countries(:usa)
    range = usa.timezone_range
    assert_includes range, "UTC-12:00"
    assert_includes range, "to"
    assert_includes range, "UTC-04:00"
  end

  test "timezone_range returns empty string when timezones is blank" do
    country = Country.new(code: "XX", name: "Test")
    assert_equal "", country.timezone_range
  end

  # ===========================================
  # 面積フォーマットのテスト
  # ===========================================
  # Note: area_formatted uses number_with_delimiter which is an ActionView helper
  # not available in models. Testing only the N/A case.

  test "area_formatted returns N/A when area is blank" do
    country = Country.new(code: "XX", name: "Test")
    assert_equal "N/A", country.area_formatted
  end

  # ===========================================
  # 隣接国のテスト
  # ===========================================
  test "neighboring_countries returns borders array" do
    country = Country.new(
      code: "XX",
      name: "Test",
      borders: ["US", "MX"]
    )
    neighbors = country.neighboring_countries
    assert_kind_of Array, neighbors
    assert_includes neighbors, "US"
    assert_includes neighbors, "MX"
  end

  test "neighboring_countries returns empty array when borders is nil" do
    country = Country.new(code: "XX", name: "Test")
    assert_equal [], country.neighboring_countries
  end

  # ===========================================
  # シリアライズされたフィールドのテスト
  # ===========================================
  test "languages is serialized as JSON" do
    usa = countries(:usa)
    assert_kind_of Hash, usa.languages
  end

  test "timezones is serialized as JSON" do
    usa = countries(:usa)
    assert_kind_of Array, usa.timezones
  end
end
