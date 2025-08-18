require "test_helper"

class AuUniversitiesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get au_universities_index_url
    assert_response :success
  end

  test "should get search" do
    get au_universities_search_url
    assert_response :success
  end

  test "should get show" do
    get au_universities_show_url
    assert_response :success
  end
end
