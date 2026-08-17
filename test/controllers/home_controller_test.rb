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

  test "home shows in-use items with low stock toggle and review link" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.start_using!(user, Time.zone.local(2026, 5, 10))
    usage_log = item.current_usage_log

    get home_path

    assert_response :success
    assert_select "h2", text: "今使っているもの"
    assert_select "a[href='#{item_path(item)}']", text: item.name
    assert_select "form[action='#{toggle_low_stock_item_path(item)}']"
    assert_select "a[href='#{edit_usage_log_path(usage_log)}']", text: "感想を書く"
  end

  test "home shows empty state when nothing is in use" do
    sign_in users(:one)

    get home_path

    assert_response :success
    assert_select ".ui-empty-state", text: /使用中のアイテムがありません/
  end

  test "home does not show other user's in-use items" do
    sign_in users(:one)

    other_item = users(:two).items.create!(name: "他ユーザーのアイテム", in_stock: true)
    other_item.start_using!(users(:two), Time.zone.local(2026, 5, 10))

    get home_path

    assert_response :success
    assert_no_match "他ユーザーのアイテム", response.body
  end
end
