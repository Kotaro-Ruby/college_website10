require "test_helper"

class AuCourseTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil au_courses(:melbourne_cs_bachelor)
    assert_not_nil au_courses(:melbourne_medicine)
    assert_not_nil au_courses(:sydney_law_bachelor)
    assert_not_nil au_courses(:sydney_mba)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid course with all required attributes" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999998X",
      course_name: "Test Course"
    )
    assert course.valid?
  end

  test "invalid without cricos_course_code" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      course_name: "Test Course"
    )
    assert_not course.valid?
    assert_includes course.errors[:cricos_course_code], "can't be blank"
  end

  test "invalid without course_name" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999997X"
    )
    assert_not course.valid?
    assert_includes course.errors[:course_name], "can't be blank"
  end

  test "invalid with duplicate cricos_course_code" do
    existing = au_courses(:melbourne_cs_bachelor)
    course = AuCourse.new(
      au_university: au_universities(:sydney),
      cricos_course_code: existing.cricos_course_code,
      course_name: "Another Course"
    )
    assert_not course.valid?
    assert_includes course.errors[:cricos_course_code], "has already been taken"
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "active scope returns only active courses" do
    AuCourse.active.each do |course|
      assert course.active
    end
  end

  test "bachelor scope returns bachelor courses" do
    AuCourse.bachelor.each do |course|
      assert course.course_level.include?("Bachelor")
    end
  end

  test "masters scope returns masters courses" do
    AuCourse.masters.each do |course|
      assert course.course_level.include?("Master")
    end
  end

  test "doctoral scope returns doctoral courses" do
    AuCourse.doctoral.each do |course|
      assert course.course_level.match?(/Doctor|PhD/i)
    end
  end

  test "by_field scope filters by field" do
    it_courses = AuCourse.by_field("Information Technology")
    it_courses.each do |course|
      assert_equal "Information Technology", course.field_of_education_broad
    end
  end

  test "with_work_component scope filters courses with work component" do
    AuCourse.with_work_component.each do |course|
      assert course.work_component
    end
  end

  # ===========================================
  # 学位カテゴリーのテスト
  # ===========================================
  test "degree_category returns Bachelor for bachelor courses" do
    course = au_courses(:melbourne_cs_bachelor)
    assert_equal "Bachelor", course.degree_category
  end

  test "degree_category returns Masters for masters courses" do
    course = au_courses(:sydney_mba)
    assert_equal "Masters", course.degree_category
  end

  test "degree_category returns Doctoral for doctoral courses" do
    course = au_courses(:melbourne_medicine)
    assert_equal "Doctoral", course.degree_category
  end

  test "degree_category returns Diploma for diploma courses" do
    course = au_courses(:monash_diploma)
    assert_equal "Diploma", course.degree_category
  end

  # ===========================================
  # 期間計算のテスト
  # ===========================================
  test "duration_in_years calculates correctly" do
    course = au_courses(:melbourne_cs_bachelor)
    # 156 weeks / 52 = 3.0 years
    assert_equal 3.0, course.duration_in_years
  end

  test "duration_in_years returns nil when duration_weeks is nil" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999996X",
      course_name: "Test"
    )
    assert_nil course.duration_in_years
  end

  # ===========================================
  # 授業料フォーマットのテスト
  # ===========================================
  test "formatted_tuition returns formatted string" do
    course = au_courses(:melbourne_cs_bachelor)
    formatted = course.formatted_tuition
    assert_includes formatted, "$"
  end

  test "formatted_tuition returns N/A when nil" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999995X",
      course_name: "Test"
    )
    assert_equal "N/A", course.formatted_tuition
  end

  # ===========================================
  # 分野の日本語表示テスト
  # ===========================================
  test "field_of_education_jp returns japanese name" do
    course = au_courses(:melbourne_cs_bachelor)
    assert_equal "情報技術", course.field_of_education_jp

    health_course = au_courses(:melbourne_medicine)
    assert_equal "健康・医療", health_course.field_of_education_jp
  end

  test "field_of_education_jp returns original when no mapping" do
    course = AuCourse.new(field_of_education_broad: "Unknown Field")
    assert_equal "Unknown Field", course.field_of_education_jp
  end

  # ===========================================
  # 検索のテスト
  # ===========================================
  test "search finds courses by name" do
    results = AuCourse.search("Computer")
    assert results.any?
  end

  test "search finds courses by field" do
    results = AuCourse.search("Information Technology")
    assert results.any?
  end

  test "search returns none for blank query" do
    results = AuCourse.search("")
    assert_empty results
  end

  # ===========================================
  # 主要コース判定のテスト
  # ===========================================
  test "major_course? returns true for bachelor, masters, doctoral" do
    assert au_courses(:melbourne_cs_bachelor).major_course?
    assert au_courses(:sydney_mba).major_course?
    assert au_courses(:melbourne_medicine).major_course?
  end

  test "major_course? returns false for diploma" do
    assert_not au_courses(:monash_diploma).major_course?
  end

  # ===========================================
  # アソシエーションのテスト
  # ===========================================
  test "belongs to university" do
    course = au_courses(:melbourne_cs_bachelor)
    assert_equal au_universities(:melbourne), course.au_university
  end

  # ===========================================
  # コールバックのテスト
  # ===========================================
  test "calculates duration_years before save" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999994X",
      course_name: "Test Course",
      duration_weeks: 104
    )
    course.save!
    assert_equal 2.0, course.duration_years
  end

  test "calculates annual_tuition_fee before save" do
    course = AuCourse.new(
      au_university: au_universities(:melbourne),
      cricos_course_code: "999993X",
      course_name: "Test Course",
      duration_weeks: 104,
      tuition_fee: 80000
    )
    course.save!
    # 80000 / 2 years = 40000
    assert_equal 40000, course.annual_tuition_fee
  end
end
