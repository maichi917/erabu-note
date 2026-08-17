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

  test "home shows highly rated and poorly rated items separately" do
    user = users(:one)
    sign_in user

    good_item = items(:one)
    good_item.start_using!(user, Time.zone.local(2026, 5, 1))
    good_item.finish_using!(Time.zone.local(2026, 5, 10), rating: 5, review: "また使いたい")

    bad_item = items(:two)
    bad_item.update!(in_stock: true)
    bad_item.start_using!(user, Time.zone.local(2026, 5, 1))
    bad_item.finish_using!(Time.zone.local(2026, 5, 5), rating: 1, review: "合わなかった")

    get home_path

    assert_response :success
    assert_select "h3", text: "よかったもの"
    assert_select "h3", text: "イマイチだったもの"
    assert_select "a[href='#{item_path(good_item)}']", text: good_item.name
    assert_select "a[href='#{item_path(bad_item)}']", text: bad_item.name
  end

  test "home shows at most 4 in-use items with a link to see more" do
    user = users(:one)
    sign_in user

    5.times do |number|
      item = user.items.create!(name: "使用中アイテム#{number}", in_stock: true)
      item.start_using!(user, Time.zone.local(2026, 5, 10))
    end

    get home_path

    assert_response :success
    assert_select "article", count: 4
    assert_select "a[href='#{in_use_items_path}']", text: "もっと見る >>"
  end

  test "home does not show the more link when 4 or fewer items are in use" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.start_using!(user, Time.zone.local(2026, 5, 10))

    get home_path

    assert_response :success
    assert_select "a[href='#{in_use_items_path}']", text: "もっと見る >>", count: 0
  end

  test "home does not show middling ratings in good or bad sections" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.start_using!(user, Time.zone.local(2026, 5, 1))
    item.finish_using!(Time.zone.local(2026, 5, 10), rating: 3)

    get home_path

    assert_response :success
    assert_includes response.body, "まだ高評価のレビューがありません"
    assert_includes response.body, "まだ低評価のレビューがありません"
  end
end
