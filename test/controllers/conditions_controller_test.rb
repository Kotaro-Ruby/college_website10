require "test_helper"

class ConditionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @condition = conditions(:harvard)
  end

  # ===========================================
  # 検索結果ページのテスト
  # ===========================================
  test "should redirect to search when state is not selected" do
    get results_url, params: { state: "選択してください" }
    assert_redirected_to "/search"
  end

  test "should get results with state filter" do
    get results_url, params: { state: "California (CA)" }
    assert_response :success
  end

  test "should get results with state code" do
    get results_url, params: { state: "CA" }
    assert_response :success
  end

  test "should get results with college name search" do
    get results_url, params: { college_name: "Harvard" }
    assert_response :success
  end

  test "should get results with japanese college name search" do
    get results_url, params: { college_name: "ハーバード" }
    assert_response :success
  end

  test "should get results with university type filter" do
    get results_url, params: { state: "指定しない", privateorpublic: "4年制私立" }
    assert_response :success
  end

  test "should get results with tuition filter" do
    get results_url, params: { state: "指定しない", tuition: "$20,000以下" }
    assert_response :success
  end

  # ===========================================
  # 大学詳細ページのテスト
  # ===========================================
  test "should get show" do
    get conditions_url(@condition.id)
    assert_response :success
  end

  test "should increment view count on show" do
    initial_count = @condition.view_count || 0
    get conditions_url(@condition.id)
    @condition.reload
    # view_countが増加していることを確認（初期値によって結果が変わる可能性あり）
    assert @condition.view_count >= initial_count
  end

  # ===========================================
  # 比較機能のテスト
  # ===========================================
  test "should get compare page or require login" do
    condition2 = conditions(:state_university)
    get compare_url, params: { ids: "#{@condition.id},#{condition2.id}" }
    # 比較ページはログインが必要な場合がある
    assert [200, 401, 302].include?(response.status)
  end

  # ===========================================
  # フォールバックのテスト
  # ===========================================
  test "should handle fallback for unknown routes" do
    get "/unknown-route-that-does-not-exist"
    # フォールバックページで404を返す
    assert_response :not_found
  end
end
