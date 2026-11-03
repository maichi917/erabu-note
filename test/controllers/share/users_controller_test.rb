require "test_helper"

class Share::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @other = users(:two)
    @shared = @other.items.create!(name: "シェアした化粧水", rating: 5, memo: "メモは見せない", shared: true)
    @other.items.create!(name: "シェアしていない乳液", rating: 4)
  end

  test "show lists only the shared reviews of the user" do
    sign_in users(:one)

    get share_user_path(@other)

    assert_response :success
    assert_select "h1", @other.name
    assert_select "article", count: 1
    assert_match "シェアした化粧水", response.body
    assert_no_match "シェアしていない乳液", response.body
    assert_no_match "メモは見せない", response.body
  end

  test "show redirects to the mypage for the current user" do
    sign_in @other

    get share_user_path(@other)

    assert_redirected_to share_mypage_path
  end

  test "show does not let a guest see other users" do
    sign_in User.create_guest!

    get share_user_path(@other)

    assert_redirected_to share_mypage_path
    assert_equal "他のユーザーのページは、新規登録すると見られます", flash[:alert]
  end
end
