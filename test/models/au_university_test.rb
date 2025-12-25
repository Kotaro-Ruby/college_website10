require "test_helper"

class AuUniversityTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil au_universities(:melbourne)
    assert_not_nil au_universities(:sydney)
    assert_not_nil au_universities(:monash)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid university with all required attributes" do
    university = AuUniversity.new(
      name: "Test University",
      cricos_provider_code: "12345X"
    )
    assert university.valid?
  end

  test "invalid without name" do
    university = AuUniversity.new(cricos_provider_code: "12345X")
    assert_not university.valid?
    assert_includes university.errors[:name], "can't be blank"
  end

  test "invalid without cricos_provider_code" do
    university = AuUniversity.new(name: "Test University")
    assert_not university.valid?
    assert_includes university.errors[:cricos_provider_code], "can't be blank"
  end

  test "invalid with duplicate cricos_provider_code" do
    existing = au_universities(:melbourne)
    university = AuUniversity.new(
      name: "Another University",
      cricos_provider_code: existing.cricos_provider_code
    )
    assert_not university.valid?
    assert_includes university.errors[:cricos_provider_code], "has already been taken"
  end

  # ===========================================
  # 基本属性のテスト
  # ===========================================
  test "melbourne has correct attributes" do
    melbourne = au_universities(:melbourne)
    assert_equal "The University of Melbourne", melbourne.name
    assert_equal "VIC", melbourne.state
    assert_equal "Melbourne", melbourne.city
    assert melbourne.active
  end

  test "sydney has correct attributes" do
    sydney = au_universities(:sydney)
    assert_equal "The University of Sydney", sydney.name
    assert_equal "NSW", sydney.state
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "active scope returns only active universities" do
    AuUniversity.active.each do |uni|
      assert uni.active
    end
  end

  test "by_state scope filters by state" do
    vic_unis = AuUniversity.by_state("VIC")
    vic_unis.each do |uni|
      assert_equal "VIC", uni.state
    end
  end

  test "ordered_by_ranking scope orders by world_ranking" do
    ranked = AuUniversity.where.not(world_ranking: nil).ordered_by_ranking.to_a
    ranked.each_cons(2) do |higher, lower|
      assert higher.world_ranking <= lower.world_ranking
    end
  end

  test "with_bachelor_programs scope filters universities with bachelor courses" do
    AuUniversity.with_bachelor_programs.each do |uni|
      assert uni.bachelor_courses_count.to_i > 0
    end
  end

  # ===========================================
  # Group of Eight判定のテスト
  # ===========================================
  test "group_of_eight? returns true for Go8 universities" do
    melbourne = au_universities(:melbourne)
    sydney = au_universities(:sydney)
    monash = au_universities(:monash)

    assert melbourne.group_of_eight?
    assert sydney.group_of_eight?
    assert monash.group_of_eight?
  end

  test "group_of_eight? returns false for non-Go8 universities" do
    inactive = au_universities(:inactive_uni)
    assert_not inactive.group_of_eight?
  end

  # ===========================================
  # 州名変換のテスト
  # ===========================================
  test "state_full_name returns full state name" do
    melbourne = au_universities(:melbourne)
    assert_equal "Victoria", melbourne.state_full_name

    sydney = au_universities(:sydney)
    assert_equal "New South Wales", sydney.state_full_name
  end

  # ===========================================
  # 人気分野のテスト
  # ===========================================
  test "popular_fields_list returns array of fields" do
    melbourne = au_universities(:melbourne)
    fields = melbourne.popular_fields_list

    assert_kind_of Array, fields
    assert_includes fields, "Engineering"
  end

  test "popular_fields_list returns empty array when nil" do
    uni = AuUniversity.new(name: "Test", cricos_provider_code: "99998X")
    assert_equal [], uni.popular_fields_list
  end

  # ===========================================
  # 授業料表示のテスト
  # ===========================================
  test "formatted_tuition_range returns formatted range" do
    melbourne = au_universities(:melbourne)
    range = melbourne.formatted_tuition_range

    assert_includes range, "$"
    assert_includes range, "-"
  end

  test "formatted_tuition_range returns N/A when tuition is nil" do
    uni = AuUniversity.new(name: "Test", cricos_provider_code: "99997X")
    assert_equal "N/A", uni.formatted_tuition_range
  end

  # ===========================================
  # 検索のテスト
  # ===========================================
  test "search finds universities by name" do
    results = AuUniversity.search("Melbourne")
    assert results.any?
    results.each do |uni|
      assert uni.name.include?("Melbourne") || uni.trading_name&.include?("Melbourne") || uni.city&.include?("Melbourne")
    end
  end

  test "search returns none for blank query" do
    results = AuUniversity.search("")
    assert_empty results
  end

  # ===========================================
  # コールバックのテスト
  # ===========================================
  test "generates slug from name" do
    uni = AuUniversity.create!(name: "Test University Name", cricos_provider_code: "88888X")
    assert_equal "test-university-name", uni.slug
  end

  test "formats website with https" do
    monash = au_universities(:monash)
    # monash has website "www.monash.edu" without https
    monash.save
    assert monash.website.start_with?("https://")
  end

  # ===========================================
  # アソシエーションのテスト
  # ===========================================
  test "has many courses" do
    melbourne = au_universities(:melbourne)
    assert melbourne.au_courses.count >= 1
  end

  test "destroying university destroys associated courses" do
    # Create a new university to avoid affecting other tests
    uni = AuUniversity.create!(name: "Temp Uni", cricos_provider_code: "77777X")
    AuCourse.create!(
      au_university: uni,
      cricos_course_code: "999999Z",
      course_name: "Temp Course"
    )

    assert_difference "AuCourse.count", -1 do
      uni.destroy
    end
  end
end
