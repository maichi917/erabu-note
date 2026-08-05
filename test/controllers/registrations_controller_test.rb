require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "edit renders the account edit page for a signed-in user" do
    sign_in users(:one)

    get edit_user_registration_path

    assert_response :success
    assert_select "h2", text: "アカウント編集"
  end

  test "update changes the user's name and email" do
    sign_in users(:one)

    patch user_registration_path, params: {
      user: {
        name: "更新後の名前",
        email: "updated@example.com",
        current_password: "password"
      }
    }

    assert_redirected_to root_path
    users(:one).reload
    assert_equal "更新後の名前", users(:one).name
    assert_equal "updated@example.com", users(:one).email
  end

  test "update without current_password fails for a regular user" do
    sign_in users(:one)

    patch user_registration_path, params: {
      user: {
        name: "更新後の名前",
        email: "updated@example.com"
      }
    }

    users(:one).reload
    assert_not_equal "更新後の名前", users(:one).name
  end

  test "update changes name and email without current_password for a LINE-linked user" do
    user = users(:one)
    user.update!(line_user_id: "line-uid-123")
    sign_in user

    patch user_registration_path, params: {
      user: {
        name: "LINE更新後の名前",
        email: "line-updated@example.com"
      }
    }

    assert_redirected_to root_path
    user.reload
    assert_equal "LINE更新後の名前", user.name
    assert_equal "line-updated@example.com", user.email
  end

  test "destroy removes the user along with their items, categories, and usage logs" do
    user = users(:one)
    item = items(:one)
    item.start_using!(user, Time.zone.local(2026, 5, 1))
    usage_log_id = item.reload.current_usage_log.id
    item_ids = user.items.ids
    category_ids = user.categories.ids

    sign_in user

    delete user_registration_path

    assert_redirected_to root_path
    assert_nil User.find_by(id: user.id)
    assert_empty Item.where(id: item_ids)
    assert_empty Category.where(id: category_ids)
    assert_nil UsageLog.find_by(id: usage_log_id)
  end
end
