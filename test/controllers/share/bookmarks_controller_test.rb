require "test_helper"

class Share::BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @item = @other.items.create!(name: "保存する化粧水", rating: 5, review: "よかった", shared: true)
  end

  test "create bookmarks the item and destroy removes it" do
    sign_in @user

    post share_item_bookmark_path(@item)

    assert_redirected_to share_timeline_path
    assert_includes @user.bookmarked_items, @item

    delete share_item_bookmark_path(@item)

    assert_empty @user.reload.bookmarked_items
  end

  test "you cannot bookmark a review that is not shared" do
    hidden = @other.items.create!(name: "シェアしていない乳液", rating: 4)
    sign_in @user

    post share_item_bookmark_path(hidden)

    assert_response :not_found
    assert_empty @user.bookmarked_items
  end

  test "a guest can bookmark a sample user's review but not a real user's" do
    User.ensure_sample_users!
    sample_item = User.samples.first.items.first
    guest = User.create_guest!
    sign_in guest

    post share_item_bookmark_path(sample_item)
    post share_item_bookmark_path(@item)

    assert_equal [ sample_item ], guest.bookmarked_items.to_a
    assert_response :not_found
  end

  test "cards show a bookmark button, filled once the review is saved" do
    sign_in @user

    get share_search_path

    assert_select "form[action='#{share_item_bookmark_path(@item)}'] button[aria-label='保存する']"

    @user.bookmark!(@item)
    get share_search_path

    assert_select "button[aria-label='保存をやめる']", count: 1
  end

  test "index lists saved reviews and hides the ones that are no longer shared" do
    other_item = @other.items.create!(name: "あとでやめる乳液", rating: 4, shared: true)
    @user.bookmark!(@item)
    @user.bookmark!(other_item)
    sign_in @user

    get share_bookmarks_path

    assert_select "article", count: 2

    other_item.update!(shared: false)
    get share_bookmarks_path

    assert_select "article", count: 1
    assert_match "保存する化粧水", response.body
  end

  test "index shows the newest saved review first" do
    second = @other.items.create!(name: "あとから保存した乳液", rating: 4, shared: true)
    @user.bookmark!(@item)
    @user.bookmark!(second)
    sign_in @user

    get share_bookmarks_path

    assert_operator response.body.index("あとから保存した乳液"), :<, response.body.index("保存する化粧水")
  end

  test "index guides to the search when nothing is saved" do
    sign_in @user

    get share_bookmarks_path

    assert_match "保存した感想はまだありません", response.body
  end
end
