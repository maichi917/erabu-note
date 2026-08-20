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

  test "home shows low stock items with a review link" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.update!(low_stock_flagged: true)

    get home_path

    assert_response :success
    assert_select "h2", text: "なくなりそう"
    assert_select "a[href='#{item_path(item)}']", text: item.name
    assert_select "a[href='#{edit_review_item_path(item)}']", text: "感想を書く"
  end

  test "home shows an edit label for the review link when the low stock item already has a rating" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.update!(low_stock_flagged: true, rating: 4)

    get home_path

    assert_response :success
    assert_select "a[href='#{edit_review_item_path(item)}']", text: "感想を編集"
  end

  test "home shows empty state when nothing is low on stock" do
    sign_in users(:one)

    get home_path

    assert_response :success
    assert_select ".ui-empty-state", text: /なくなりそうなアイテムはありません/
  end

  test "home does not show other user's low stock items" do
    sign_in users(:one)

    other_item = users(:two).items.create!(name: "他ユーザーのアイテム", low_stock_flagged: true)

    get home_path

    assert_response :success
    assert_no_match "他ユーザーのアイテム", response.body
  end

  test "home does not show archived items even if low stock" do
    sign_in users(:one)

    item = items(:one)
    item.update!(low_stock_flagged: true, archived: true)

    get home_path

    assert_response :success
    assert_select ".ui-empty-state", text: /なくなりそうなアイテムはありません/
  end

  test "home shows unreviewed items with a review link" do
    user = users(:one)
    sign_in user

    item = items(:one)

    get home_path

    assert_response :success
    assert_select "h2", text: "レビュー未記入"
    assert_select "a[href='#{item_path(item)}']", text: item.name
    assert_select "a[href='#{edit_review_item_path(item)}']", text: "感想を書く"
  end

  test "home does not show reviewed items in the unreviewed section" do
    user = users(:one)
    sign_in user

    items(:one).update!(rating: 4, review: "よかった")
    items(:two).update!(rating: 5, review: "とても良かった")

    get home_path

    assert_response :success
    assert_select ".ui-empty-state", text: /未記入のレビューはありません/
  end

  test "home shows highly rated and poorly rated items separately" do
    user = users(:one)
    sign_in user

    good_item = items(:one)
    good_item.update!(rating: 5, review: "また使いたい")

    bad_item = items(:two)
    bad_item.update!(rating: 1, review: "合わなかった")

    get home_path

    assert_response :success
    assert_select "h3", text: "よかったもの"
    assert_select "h3", text: "イマイチだったもの"
    assert_select "a[href='#{item_path(good_item)}']", text: good_item.name
    assert_select "a[href='#{item_path(bad_item)}']", text: bad_item.name
  end

  test "home shows at most 4 low stock items with a link to see more" do
    user = users(:one)
    sign_in user

    5.times do |number|
      user.items.create!(name: "なくなりそうアイテム#{number}", low_stock_flagged: true)
    end

    get home_path

    assert_response :success
    assert_select "a[href='#{items_path(status: "low_stock")}']", text: "もっと見る >>"
  end

  test "home does not show the more link when 4 or fewer items are low on stock" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.update!(low_stock_flagged: true)

    get home_path

    assert_response :success
    assert_select "a[href='#{items_path(status: "low_stock")}']", text: "もっと見る >>", count: 0
  end

  test "home does not show middling ratings in good or bad sections" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.update!(rating: 3)

    get home_path

    assert_response :success
    assert_includes response.body, "まだ高評価のレビューがありません"
    assert_includes response.body, "まだ低評価のレビューがありません"
  end

  test "home does not show archived items in good or bad sections" do
    user = users(:one)
    sign_in user

    item = items(:one)
    item.update!(rating: 5, archived: true)

    get home_path

    assert_response :success
    assert_includes response.body, "まだ高評価のレビューがありません"
  end
end
