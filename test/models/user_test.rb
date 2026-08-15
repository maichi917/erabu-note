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

  test "seed_guest_sample_data! creates sample categories, items, and usage logs" do
    guest = User.create_guest!

    guest.seed_guest_sample_data!

    assert_equal 3, guest.categories.count
    assert_equal 4, guest.items.count
    assert_equal 3, guest.usage_logs.count
  end
end
