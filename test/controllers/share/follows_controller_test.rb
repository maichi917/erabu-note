require "test_helper"

class Share::FollowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "create follows the user and destroy unfollows" do
    sign_in @user

    post share_user_follow_path(@other)

    assert_redirected_to share_user_path(@other)
    assert @user.following?(@other)

    delete share_user_follow_path(@other)

    assert_not @user.reload.following?(@other)
  end

  test "a guest can follow sample users only" do
    User.ensure_sample_users!
    guest = User.create_guest!
    sign_in guest

    post share_user_follow_path(User.samples.first)
    post share_user_follow_path(@other)

    assert_equal [ User.samples.first ], guest.following.to_a
    assert_response :not_found
  end

  test "a user cannot follow themselves" do
    sign_in @user

    post share_user_follow_path(@user)

    assert_response :not_found
  end

  test "create saves the nickname confirmed when following for the first time" do
    sign_in @user

    post share_user_follow_path(@other), params: { nickname: " まい " }

    assert_equal "まい", @user.reload.name
    assert @user.following?(@other)
  end

  test "the follow button asks for the nickname only until you have shared or followed" do
    sign_in @user

    get share_user_path(@other)
    assert_select "dialog"

    @user.follow!(@other)
    @user.unfollow!(@other)
    @user.items.create!(name: "シェア済み", rating: 5, shared: true)

    get share_user_path(@other)
    assert_select "dialog", count: 0
  end
end
