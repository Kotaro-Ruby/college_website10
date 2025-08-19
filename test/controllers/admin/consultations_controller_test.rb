require "test_helper"

class Admin::ConsultationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    @consultation = consultations(:one)
    # Simulate admin login
    post admin_login_url, params: { username: @admin.username, password: 'password123' }
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
    patch admin_consultation_url(@consultation), params: { consultation: { status: 'confirmed' } }
    assert_redirected_to admin_consultations_url
  end

  test "should destroy consultation" do
    assert_difference('Consultation.count', -1) do
      delete admin_consultation_url(@consultation)
    end
    assert_redirected_to admin_consultations_url
  end
end
