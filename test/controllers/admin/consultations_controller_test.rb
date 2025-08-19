require "test_helper"

class Admin::ConsultationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @consultation = consultations(:one)
  end

  test "should get index" do
    get admin_consultations_url
    assert_response :success
  end

  test "should get show" do
    get admin_consultation_url(@consultation)
    assert_response :success
  end

  test "should update consultation" do
    skip "Admin authentication not implemented in test"
  end

  test "should destroy consultation" do
    skip "Admin authentication not implemented in test"
  end
end
