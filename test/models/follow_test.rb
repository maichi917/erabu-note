require "test_helper"

class FollowTest < ActiveSupport::TestCase
  setup do
    @one = users(:one)
    @two = users(:two)
  end

  test "a user can follow and unfollow another user" do
    @one.follow!(@two)

    assert @one.following?(@two)
    assert_includes @two.followers, @one
    assert_not @two.following?(@one)

    @one.unfollow!(@two)

    assert_not @one.reload.following?(@two)
  end

  test "following the same user twice keeps one follow" do
    @one.follow!(@two)

    assert_no_difference "Follow.count" do
      @one.follow!(@two)
    end
  end

  test "deleting a user deletes their follows" do
    @one.follow!(@two)
    @two.follow!(@one)

    assert_difference "Follow.count", -2 do
      @one.destroy!
    end
  end
end
