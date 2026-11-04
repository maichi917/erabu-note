require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @item = users(:two).items.create!(name: "保存する化粧水", rating: 5, review: "よかった", shared: true)
  end

  test "a user can bookmark and unbookmark an item" do
    @user.bookmark!(@item)

    assert_includes @user.bookmarked_items, @item

    @user.unbookmark!(@item)

    assert_empty @user.reload.bookmarked_items
  end

  test "bookmarking the same item twice keeps one bookmark" do
    @user.bookmark!(@item)

    assert_no_difference "Bookmark.count" do
      @user.bookmark!(@item)
    end
  end

  test "deleting a user or an item deletes the bookmarks" do
    @user.bookmark!(@item)
    users(:two).bookmark!(@item)

    assert_difference "Bookmark.count", -1 do
      @user.destroy!
    end
    assert_difference "Bookmark.count", -1 do
      @item.destroy!
    end
  end
end
