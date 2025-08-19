require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get top_url
    assert_response :success
  end
end
