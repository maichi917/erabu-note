require "test_helper"

class Share::TimelinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @other.items.create!(name: "フォローしている人の化粧水", rating: 5, review: "タイムラインに出る", shared: true)
  end

  test "show lists shared reviews of the users you follow" do
    @user.follow!(@other)
    sign_in @user

    get share_timeline_path

    assert_response :success
    assert_match "タイムラインに出る", response.body
  end

  test "show guides to search when you follow nobody" do
    sign_in @user

    get share_timeline_path

    assert_no_match "タイムラインに出る", response.body
    assert_select "a[href='#{share_search_path}']", text: "さがすから、気になるアイテムの感想を見つけよう"
  end

  test "a red dot appears for new reviews and disappears after opening the timeline" do
    @user.follow!(@other)
    sign_in @user

    get home_path
    assert_select "[aria-label='新着あり']"

    get share_timeline_path
    get home_path
    assert_select "[aria-label='新着あり']", count: 0
  end

end
