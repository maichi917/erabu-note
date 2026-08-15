require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "guest_sign_in creates a guest account with sample data and signs in" do
    assert_difference "User.count", 1 do
      post guest_sign_in_path
    end

    assert_redirected_to items_path
    guest = User.guests.order(created_at: :desc).first
    assert guest.guest?
    assert_equal 4, guest.items.count
  end

  test "guest_sign_in reuses the current guest account when already signed in as guest" do
    post guest_sign_in_path

    assert_no_difference "User.count" do
      post guest_sign_in_path
    end

    assert_redirected_to items_path
  end
end
