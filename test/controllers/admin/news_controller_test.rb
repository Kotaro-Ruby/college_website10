require "test_helper"

class Admin::NewsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_news_index_url
    assert_response :success
  end

  test "should get fetch" do
    get admin_news_fetch_url
    assert_response :success
  end

  test "should get edit" do
    get admin_news_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_news_update_url
    assert_response :success
  end

  test "should get publish" do
    get admin_news_publish_url
    assert_response :success
  end
end
