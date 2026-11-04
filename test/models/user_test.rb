require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email including domain suffix" do
    user = User.new(name: "テストユーザー", email: "user@example.com", password: "password")

    assert user.valid?
  end

  test "invalid without email domain suffix" do
    user = User.new(name: "テストユーザー", email: "admin@admin", password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email], "の形式が正しくありません"
  end

  test "create_guest! creates a unique guest account each time" do
    guest1 = User.create_guest!
    guest2 = User.create_guest!

    assert_not_equal guest1.id, guest2.id
    assert_not_equal guest1.email, guest2.email
    assert guest1.email.end_with?("@#{User::GUEST_EMAIL_DOMAIN}")
  end

  test "seed_guest_sample_data! fills each home section" do
    guest = User.create_guest!
    guest.seed_guest_sample_data!

    visible = guest.items.visible
    assert_equal 5, guest.categories.count
    assert_equal 16, guest.items.count
    assert_equal 3, visible.low_stock.count
    assert_equal 4, visible.unreviewed.count
    assert_operator visible.highly_rated.count, :>=, 4
    assert_equal 3, visible.poorly_rated.count
    assert_equal 2, guest.items.archived.count
    assert_equal 2, guest.items.count { |item| item.image.attached? }
  end

  test "guest? is true for a guest account and false for a regular user" do
    guest = User.create_guest!

    assert guest.guest?
    assert_not users(:one).guest?
  end

  test "guests scope returns only guest accounts" do
    guest = User.create_guest!

    assert_includes User.guests, guest
    assert_not_includes User.guests, users(:one)
  end

  test "ensure_sample_users! creates sample users with shared reviews only once" do
    User.ensure_sample_users!

    assert_no_difference [ "User.count", "Item.count" ] do
      User.ensure_sample_users!
    end
    assert_equal 3, User.samples.count
    assert User.samples.all? { |user| user.items.shared.any? }
  end

  test "visible_to shows sample users and themselves to guests, and only real users to others" do
    User.ensure_sample_users!
    guest = User.create_guest!

    assert_equal (User.samples.to_a + [ guest ]).sort_by(&:id), User.visible_to(guest).to_a.sort_by(&:id)
    assert_includes User.visible_to(users(:one)), users(:two)
    assert_not_includes User.visible_to(users(:one)), guest
    assert_empty User.visible_to(users(:one)) & User.samples
  end

  test "nickname_confirmed? is true for guests and for users who have shared or followed" do
    user = users(:one)
    assert_not user.nickname_confirmed?

    user.follow!(users(:two))
    assert user.nickname_confirmed?

    user.unfollow!(users(:two))
    assert_not user.nickname_confirmed?

    user.items.create!(name: "シェア中", rating: 4, shared: true)
    assert user.nickname_confirmed?

    assert User.create_guest!.nickname_confirmed?
  end
end
