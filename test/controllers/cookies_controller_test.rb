require 'test_helper'

class CookiesControllerTest < ActionController::TestCase
  test "should get pixel" do
    get :pixel
    assert_response :success
  end

end
