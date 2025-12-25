require "test_helper"

class ConsultationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_consultation_url
    assert_response :success
  end

  test "should create consultation" do
    assert_difference('Consultation.count') do
      post consultations_url, params: { 
        consultation: { 
          name: "Test User", 
          email: "test@example.com", 
          phone: "1234567890",
          timezone: "JST",
          consultation_type: "general",
          message: "Test message",
          preferred_dates: ["2025-01-20"],
          preferred_times: ["10:00"]
        } 
      }
    end
    assert_redirected_to consultation_url(Consultation.last)
  end

  test "should get show" do
    @consultation = consultations(:pending_consultation)
    get consultation_url(@consultation)
    assert_response :success
  end
end
