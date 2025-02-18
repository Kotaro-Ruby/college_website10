require "test_helper"

class Test1ControllerTest < ActionDispatch::IntegrationTest
  test "should get test1" do
    get test1_test1_url
    assert_response :success
  end
end
