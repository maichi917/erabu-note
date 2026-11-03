require "test_helper"

class Share::NicknamesControllerTest < ActionDispatch::IntegrationTest
  test "update changes the nickname" do
    user = users(:one)
    sign_in user

    patch share_nickname_path, params: { user: { name: " まい " } }

    assert_redirected_to share_mypage_path
    assert_equal "まい", user.reload.name
  end

  test "update rejects a blank nickname" do
    user = users(:one)
    sign_in user

    patch share_nickname_path, params: { user: { name: " " } }

    assert_response :unprocessable_entity
    assert_equal "テストユーザー1", user.reload.name
  end

  test "edit does not let a guest change the nickname" do
    sign_in User.create_guest!

    get edit_share_nickname_path

    assert_redirected_to share_mypage_path
  end
end
