require "test_helper"

class UsageLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user

    @item = items(:one)
    @item.start_using!(@user, Time.zone.local(2026, 5, 10))
    @item.finish_using!(Time.zone.local(2026, 5, 12))
    @usage_log = @item.usage_logs.finished.first
  end

  test "edit shows rating and review form" do
    get edit_usage_log_path(@usage_log)

    assert_response :success
    assert_select "select[name='usage_log[rating]']"
    assert_select "option[value='5']", text: "⭐️ 5"
    assert_select "textarea[name='usage_log[review]']"
    assert_select "a[href='#{item_path(@item)}']", text: "レビューしない"
  end

  test "edit allows editing the current in-use usage log" do
    in_use_item = items(:two)
    in_use_item.update!(in_stock: true)
    in_use_item.start_using!(@user, Time.zone.local(2026, 5, 20))
    in_use_log = in_use_item.current_usage_log

    get edit_usage_log_path(in_use_log)

    assert_response :success
    assert_select "select[name='usage_log[rating]']"
  end

  test "update saves rating and review while the item is still in use" do
    in_use_item = items(:two)
    in_use_item.update!(in_stock: true)
    in_use_item.start_using!(@user, Time.zone.local(2026, 5, 20))
    in_use_log = in_use_item.current_usage_log

    patch usage_log_path(in_use_log), params: {
      usage_log: {
        rating: 3,
        review: "使用中の感想"
      }
    }

    assert_redirected_to item_path(in_use_item)
    assert_equal 3, in_use_log.reload.rating
    assert_equal "使用中の感想", in_use_log.review
    assert in_use_log.in_use?
  end

  test "show displays usage log detail" do
    get usage_log_path(@usage_log)

    assert_response :success
    assert_includes response.body, @item.name
    assert_includes response.body, "使い始め日"
    assert_includes response.body, "終了日"
    assert_includes response.body, "使用期間"
    assert_select "a[href='#{item_path(@item)}']", text: "アイテム本体を見る"
  end

  test "reviews shows finished usage logs with rating and review" do
    @usage_log.update!(rating: 4, review: "また使いたい")

    get reviews_usage_logs_path

    assert_response :success
    assert_includes response.body, @item.name
    assert_select "p", text: /★★★★\s*☆/
    assert_includes response.body, "また使いたい"
    assert_select "a[href='#{edit_usage_log_path(@usage_log)}']", text: "編集"
  end

  test "reviews shows rated usage log without review as no review" do
    @usage_log.update!(rating: 4, review: "")

    get reviews_usage_logs_path

    assert_response :success
    assert_includes response.body, @item.name
    assert_select "p", text: /★★★★\s*☆/
    assert_includes response.body, "レビューなし"
  end

  test "reviews does not show unrated usage logs" do
    get reviews_usage_logs_path

    assert_response :success
    assert_no_match @item.name, response.body
  end

  test "reviews does not show other user's usage logs" do
    other_user = users(:two)
    other_item = other_user.items.create!(name: "他のアイテム", in_stock: true)
    other_item.start_using!(other_user, Time.zone.local(2026, 5, 10))
    other_item.finish_using!(Time.zone.local(2026, 5, 12), rating: 5, review: "他ユーザー")

    get reviews_usage_logs_path

    assert_response :success
    assert_no_match "他のアイテム", response.body
    assert_no_match "他ユーザー", response.body
  end

  test "reviews searches rated usage logs by item name" do
    @usage_log.update!(rating: 4, review: "また使いたい")
    other_item = items(:two)
    other_item.update!(in_stock: true)
    other_item.start_using!(@user, Time.zone.local(2026, 5, 11))
    other_item.finish_using!(
      Time.zone.local(2026, 5, 13),
      rating: 5,
      review: "しっとりした"
    )

    get reviews_usage_logs_path, params: { q: "化粧" }

    assert_response :success
    assert_includes response.body, @item.name
    assert_no_match other_item.name, response.body
    assert_select "input[name='q'][value='化粧']"
    assert_select "a[href='#{reviews_usage_logs_path}']", text: "リセット"
  end

  test "reviews shows a message when search has no results" do
    get reviews_usage_logs_path, params: { q: "存在しないアイテム" }

    assert_response :success
    assert_includes response.body, "条件に合う評価・レビュー履歴がありません"
    assert_select "a[href='#{reviews_usage_logs_path}']", text: "検索条件をリセット"
  end

  test "reviews filters usage logs by item category" do
    @item.update!(category: categories(:hair_care))
    @usage_log.update!(rating: 4)
    other_item = items(:two)
    other_item.update!(in_stock: true, category: categories(:skin_care))
    other_item.start_using!(@user, Time.zone.local(2026, 5, 11))
    other_item.finish_using!(Time.zone.local(2026, 5, 13), rating: 5)

    get reviews_usage_logs_path, params: { category_id: categories(:hair_care).id }

    assert_response :success
    assert_includes response.body, @item.name
    assert_no_match other_item.name, response.body
    assert_select "a.bg-emerald-600[href='#{reviews_usage_logs_path(category_id: categories(:hair_care).id)}']", text: categories(:hair_care).name
    assert_select "a[href='#{reviews_usage_logs_path(category_id: "uncategorized")}']", text: "未設定"
  end

  test "reviews combines item name and category filters" do
    @item.update!(category: categories(:hair_care))
    @usage_log.update!(rating: 4)
    other_item = items(:two)
    other_item.update!(in_stock: true, category: categories(:hair_care))
    other_item.start_using!(@user, Time.zone.local(2026, 5, 11))
    other_item.finish_using!(Time.zone.local(2026, 5, 13), rating: 5)

    get reviews_usage_logs_path, params: {
      q: "化粧",
      category_id: categories(:hair_care).id
    }

    assert_response :success
    assert_includes response.body, @item.name
    assert_no_match other_item.name, response.body
    assert_select "input[type='hidden'][name='category_id'][value='#{categories(:hair_care).id}']"
  end

  test "reviews filters usage logs by rating" do
    @usage_log.update!(rating: 4, review: "また使いたい")
    other_item = items(:two)
    other_item.update!(in_stock: true)
    other_item.start_using!(@user, Time.zone.local(2026, 5, 11))
    other_item.finish_using!(Time.zone.local(2026, 5, 13), rating: 5)

    get reviews_usage_logs_path, params: { rating: "4" }

    assert_response :success
    assert_includes response.body, @item.name
    assert_no_match other_item.name, response.body
    assert_select "a.bg-emerald-600[href='#{reviews_usage_logs_path(rating: 4)}']", text: /⭐️\s*4/
  end

  test "reviews search form keeps selected rating" do
    @usage_log.update!(rating: 4)

    get reviews_usage_logs_path, params: { rating: "4" }

    assert_response :success
    assert_select "input[type='hidden'][name='rating'][value='4']"
  end

  test "reviews rating filters keep selected category" do
    category = categories(:hair_care)
    @item.update!(category: category)
    @usage_log.update!(rating: 4)

    get reviews_usage_logs_path, params: { category_id: category.id }

    assert_response :success
    assert_select "a[href='#{reviews_usage_logs_path(category_id: category.id, rating: 4)}']", text: /⭐️\s*4/
  end

  test "reviews filters usage logs for uncategorized items" do
    @item.update!(category: categories(:hair_care))
    @usage_log.update!(rating: 4)
    other_item = items(:two)
    other_item.update!(in_stock: true)
    other_item.start_using!(@user, Time.zone.local(2026, 5, 11))
    other_item.finish_using!(Time.zone.local(2026, 5, 13), rating: 5)

    get reviews_usage_logs_path, params: { category_id: "uncategorized" }

    assert_response :success
    assert_includes response.body, other_item.name
    assert_no_match @item.name, response.body
  end

  test "reviews keeps search category and rating filters in pagination links" do
    category = categories(:hair_care)
    11.times do |number|
      item = @user.items.create!(
        name: "検索対象#{number}",
        in_stock: true,
        category: category
      )
      item.start_using!(@user, Time.zone.local(2026, 5, 10))
      item.finish_using!(Time.zone.local(2026, 5, 12), rating: 4)
    end

    get reviews_usage_logs_path, params: {
      q: "検索対象",
      category_id: category.id,
      rating: "4"
    }

    assert_response :success
    assert_select "a[href='#{reviews_usage_logs_path(
      page: 2,
      q: "検索対象",
      category_id: category.id,
      rating: "4"
    )}']"
  end

  test "header links to reviews page" do
    get reviews_usage_logs_path

    assert_response :success
    assert_select "a[href='#{reviews_usage_logs_path}']", text: "感想"
  end

  test "update saves rating and review" do
    patch usage_log_path(@usage_log), params: {
      usage_log: {
        rating: 5,
        review: "使いやすい"
      }
    }

    assert_redirected_to item_path(@item)
    assert_equal 5, @usage_log.reload.rating
    assert_equal "使いやすい", @usage_log.review
  end

  test "update rerenders edit when rating is invalid" do
    patch usage_log_path(@usage_log), params: {
      usage_log: {
        rating: 6,
        review: "評価が範囲外"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, "入力内容を確認してください"
    assert_nil @usage_log.reload.rating
  end

  test "other user's usage log cannot be edited" do
    other_user = users(:two)
    other_item = other_user.items.create!(name: "他のアイテム", in_stock: true)
    other_item.start_using!(other_user, Time.zone.local(2026, 5, 10))
    other_item.finish_using!(Time.zone.local(2026, 5, 12))
    other_usage_log = other_item.usage_logs.finished.first

    get edit_usage_log_path(other_usage_log)

    assert_response :not_found
  end

  test "other user's usage log cannot be shown" do
    other_user = users(:two)
    other_item = other_user.items.create!(name: "他のアイテム", in_stock: true)
    other_item.start_using!(other_user, Time.zone.local(2026, 5, 10))
    other_item.finish_using!(Time.zone.local(2026, 5, 12))
    other_usage_log = other_item.usage_logs.finished.first

    get usage_log_path(other_usage_log)

    assert_response :not_found
  end
end
