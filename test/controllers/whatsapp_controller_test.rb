require "test_helper"

class WhatsappControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get whatsapp_create_url
    assert_response :success
  end
end
