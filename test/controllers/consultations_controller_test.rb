require "test_helper"

class ConsultationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_consultation_url
    assert_response :success
  end

  test "should create consultation" do
    assert_difference('Consultation.count') do
      post consultations_url, params: { consultation: { name: "Test", email: "test@example.com", message: "Test message" } }
    end
    assert_redirected_to consultation_url(Consultation.last)
  end

  test "should get show" do
    @consultation = consultations(:one)
    get consultation_url(@consultation)
    assert_response :success
  end
end
