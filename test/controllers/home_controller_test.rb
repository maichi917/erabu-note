require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "signed in user can view the home page" do
    sign_in users(:one)

    get home_path

    assert_response :success
    assert_select "h1", "ホーム"
  end

  test "signed out visitor is redirected to sign in" do
    get home_path

    assert_redirected_to new_user_session_path
  end
end
