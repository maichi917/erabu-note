require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "index searches current user's items by partial name" do
    other_user_item = users(:two).items.create!(
      name: "化粧水 他ユーザー",
      in_stock: true
    )

    get items_path, params: { q: "化粧" }

    assert_response :success
    assert_select "h2", text: items(:one).name
    assert_includes response.body, items(:one).name
    assert_no_match items(:two).name, response.body
    assert_no_match other_user_item.name, response.body
  end

  test "index keeps search query and shows reset link" do
    get items_path, params: { q: "化粧" }

    assert_response :success
    assert_select "input[name='q'][value='化粧']"
    assert_select "a[href='#{items_path}']", text: "リセット"
  end

  test "header shows mobile and desktop navigation" do
    get items_path

    assert_response :success
    assert_select "img[src*='logo-mark'][alt='']"
    assert_select "nav[aria-label='スマートフォンメニュー'].pc\\:hidden" do
      assert_select "a[href='#{home_path}']", text: "ホーム"
      assert_select "a[href='#{items_path}']", text: "持ち物"
      assert_select "a[href='#{reviews_usage_logs_path}']", text: "感想"
      assert_select "a[href='#{new_item_path}']", text: "登録"
    end
    assert_select "nav[aria-label='メインメニュー'].pc\\:flex" do
      assert_select "a.border-emerald-600[href='#{items_path}']", text: "持ち物"
      assert_select "a[href='#{home_path}']", text: "ホーム"
      assert_select "a[href='#{reviews_usage_logs_path}']", text: "感想"
      assert_select "a[href='#{new_item_path}']", text: "登録"
    end
  end

  test "autocomplete returns matching item names for current user" do
    @user.items.create!(name: "化粧水A", in_stock: true)
    @user.items.create!(name: "化粧水B", in_stock: true)
    @user.items.create!(name: "歯ブラシ", in_stock: true)

    get autocomplete_items_path, params: { q: "化粧" }

    assert_response :success
    names = JSON.parse(response.body)
    assert_includes names, "化粧水A"
    assert_includes names, "化粧水B"
    assert_not_includes names, "歯ブラシ"
  end

  test "autocomplete excludes other user's items" do
    users(:two).items.create!(name: "化粧水X", in_stock: true)

    get autocomplete_items_path, params: { q: "化粧" }

    assert_response :success
    assert_not_includes JSON.parse(response.body), "化粧水X"
  end

  test "autocomplete limits results to 10" do
    12.times { |i| @user.items.create!(name: "検索アイテム#{i}", in_stock: true) }

    get autocomplete_items_path, params: { q: "検索アイテム" }

    assert_response :success
    assert_equal 10, JSON.parse(response.body).size
  end

  test "autocomplete returns empty array for query shorter than 2 characters" do
    @user.items.create!(name: "化粧水", in_stock: true)

    get autocomplete_items_path, params: { q: "化" }

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "index shows a message when search has no results" do
    get items_path, params: { q: "存在しないアイテム" }

    assert_response :success
    assert_includes response.body, "条件に合うアイテムがありません"
    assert_select "a[href='#{items_path}']", text: "検索条件をリセット"
  end

  test "index shows scope tabs and attribute tag chips" do
    get items_path

    assert_response :success
    assert_select "a[href='#{items_path}']", text: "すべて"
    assert_select "a[href='#{items_path(scope: "archived")}']", text: "手放したもの"
    assert_select "a[href='#{items_path(favorite: "1")}']", text: "♡ よく使うもの"
    assert_select "a[href='#{items_path(low_stock: "1")}']", text: "なくなりそう"
    assert_select "a[href='#{items_path(unreviewed: "1")}']", text: "レビュー未記入"
  end

  test "index does not show attribute tag chips on the archived scope" do
    get items_path, params: { scope: "archived" }

    assert_response :success
    assert_select "a[href='#{items_path(scope: "archived", favorite: "1")}']", count: 0
  end

  test "index filters unreviewed items" do
    unreviewed_item = items(:one)
    items(:two).update!(rating: 4)

    get items_path, params: { unreviewed: "1" }

    assert_response :success
    assert_includes response.body, unreviewed_item.name
    assert_no_match items(:two).name, response.body
  end

  test "index filters favorite items" do
    favorite_item = items(:one)
    favorite_item.update!(favorite: true)

    get items_path, params: { favorite: "1" }

    assert_response :success
    assert_includes response.body, favorite_item.name
    assert_no_match items(:two).name, response.body
  end

  test "index filters low stock items by status" do
    low_stock_item = items(:one)
    low_stock_item.update!(low_stock_flagged: true)

    get items_path, params: { low_stock: "1" }

    assert_response :success
    assert_includes response.body, low_stock_item.name
    assert_no_match items(:two).name, response.body
  end

  test "index combines multiple attribute tag filters" do
    both = items(:one)
    both.update!(favorite: true, low_stock_flagged: true)
    only_favorite = items(:two)
    only_favorite.update!(favorite: true, low_stock_flagged: false)

    get items_path, params: { favorite: "1", low_stock: "1" }

    assert_response :success
    assert_includes response.body, both.name
    assert_no_match only_favorite.name, response.body
  end

  test "index shows archived items only on the archived tab, with a restore link" do
    archived_item = items(:two)
    archived_item.update!(archived: true)

    get items_path, params: { scope: "archived" }

    assert_response :success
    assert_includes response.body, archived_item.name
    assert_no_match items(:one).name, response.body
    assert_select "a[href='#{unarchive_item_path(archived_item)}']", text: "リストに戻す"
    assert_select "a[href='#{item_path(archived_item, anchor: "review")}']", text: "感想を書く"
  end

  test "index does not show archived items on the all tab" do
    items(:two).update!(archived: true)

    get items_path

    assert_response :success
    assert_no_match items(:two).name, response.body
  end

  test "toggle_favorite switches item favorite state" do
    item = items(:one)

    assert_changes -> { item.reload.favorite? }, from: false, to: true do
      patch toggle_favorite_item_path(item)
    end

    assert_redirected_to item_path(item)
  end

  test "index links item information to detail page" do
    item = items(:one)

    get items_path

    assert_response :success
    assert_select "a[aria-label='#{item.name}の詳細を見る'][href='#{item_path(item)}']"
  end

  test "index shows favorite toggle button for every item" do
    item = items(:one)

    get items_path

    assert_response :success
    assert_select "form[action='#{toggle_favorite_item_path(item)}']"
  end

  test "index shows the item's rating" do
    item = items(:one)
    item.update!(rating: 4)

    get items_path

    assert_response :success
    assert_select "article span.text-yellow-500", text: /★★★★\s*☆/
  end

  test "index shows the review snippet when the item has a review" do
    item = items(:one)
    item.update!(rating: 4, review: "泡立ちが良くて香りも好み")

    get items_path

    assert_response :success
    assert_includes response.body, "泡立ちが良くて香りも好み"
  end

  test "index does not show a review snippet when the item has no review" do
    item = items(:one)

    get items_path

    assert_response :success
    assert_select "article p.italic", count: 0
  end

  test "index does not show a rating for an item without any reviews" do
    item = items(:one)

    get items_path

    assert_response :success
    assert_select "article span.text-yellow-500", count: 0
  end

  test "index shows brand name above the item name for each row" do
    item = items(:one)
    item.update!(brand_name: "ものログ製薬")

    get items_path

    assert_response :success
    assert_select "article p.text-emerald-700", text: "ものログ製薬"
    assert response.body.index("ものログ製薬") < response.body.index(">#{item.name}<")
  end

  test "index shows low stock toggle, review link, and archive link for a visible item" do
    item = items(:one)

    get items_path

    assert_response :success
    assert_select "article form[action='#{toggle_low_stock_item_path(item)}']"
    assert_select "article a[href='#{item_path(item, anchor: "review")}']", text: "感想を書く"
    assert_select "article a[href='#{confirm_archive_item_path(item)}']", text: "手放す"
  end

  test "index shows an edit label for the review link when the item already has a rating" do
    item = items(:one)
    item.update!(rating: 4)

    get items_path

    assert_response :success
    assert_select "article a[href='#{item_path(item, anchor: "review")}']", text: "感想を編集"
  end

  test "index filters items by category" do
    items(:one).update!(category: categories(:hair_care))
    items(:two).update!(category: categories(:skin_care))

    get items_path, params: { category_id: categories(:hair_care).id }

    assert_response :success
    assert_includes response.body, items(:one).name
    assert_no_match items(:two).name, response.body
  end

  test "index combines name and category filters" do
    items(:one).update!(category: categories(:hair_care))
    items(:two).update!(category: categories(:hair_care))

    get items_path, params: {
      q: "化粧",
      category_id: categories(:hair_care).id
    }

    assert_response :success
    assert_includes response.body, items(:one).name
    assert_no_match items(:two).name, response.body
  end

  test "index filters uncategorized items" do
    items(:one).update!(category: categories(:hair_care))

    get items_path, params: { category_id: "uncategorized" }

    assert_response :success
    assert_includes response.body, items(:two).name
    assert_no_match items(:one).name, response.body
  end

  test "index does not show another user's items for another user's category" do
    other_user = users(:two)
    other_category = other_user.categories.create!(name: "他ユーザーカテゴリ")
    other_item = other_user.items.create!(
      name: "他ユーザーアイテム",
      in_stock: true,
      category: other_category
    )

    get items_path, params: { category_id: other_category.id }

    assert_response :success
    assert_no_match other_item.name, response.body
  end

  test "index search form keeps selected category" do
    category = categories(:hair_care)

    get items_path, params: { category_id: category.id }

    assert_response :success
    assert_select "input[type='hidden'][name='category_id'][value='#{category.id}']"
  end

  test "index shows category options in dropdown" do
    category = categories(:hair_care)

    get items_path

    assert_response :success
    assert_select "select[name='category_id']" do
      assert_select "option", text: category.name
      assert_select "option", text: "未設定"
    end
  end

  test "index status filters keep selected category" do
    category = categories(:hair_care)

    get items_path, params: { category_id: category.id }

    assert_response :success
    assert_select "a[href='#{items_path(category_id: category.id, favorite: "1")}']", text: "♡ よく使うもの"
  end

  test "index does not show reset link when only category is selected" do
    get items_path, params: { category_id: categories(:hair_care).id }

    assert_response :success
    assert_select "a[href='#{items_path}']", text: "リセット", count: 0
  end

  test "index shows a message when category filter has no results" do
    empty_category = @user.categories.create!(name: "アイテムなし")

    get items_path, params: { category_id: empty_category.id }

    assert_response :success
    assert_includes response.body, "アイテムがありません"
    assert_select "a[href='#{items_path}']", text: "検索条件をリセット", count: 0
  end

  test "index keeps search category and status filters in pagination links" do
    category = categories(:hair_care)
    11.times do |number|
      @user.items.create!(
        name: "検索対象#{number}",
        in_stock: true,
        category: category
      )
    end

    get items_path, params: {
      q: "検索対象",
      category_id: category.id
    }

    assert_response :success
    assert_select "a[href='#{items_path(
      page: 2,
      q: "検索対象",
      category_id: category.id
    )}']"
  end

  test "confirm_archive shows the review form and a real archive button" do
    item = items(:one)
    item.update!(rating: 4, review: "よかった")

    get confirm_archive_item_path(item)

    assert_response :success
    assert_includes response.body, item.name
    assert_select "form[action='#{update_review_item_path(item)}'] input[type='hidden'][name='return_to'][value='confirm_archive']"
    assert_select "a[href='#{archive_item_path(item)}']", text: "このアイテムを手放す"
  end

  test "update_review redirects back to confirm_archive when return_to is set" do
    item = items(:one)

    patch update_review_item_path(item), params: { item: { rating: 4, review: "よかった" }, return_to: "confirm_archive" }

    assert_redirected_to confirm_archive_item_path(item)
  end

  test "archive archives item and clears low_stock_flagged and favorite" do
    item = items(:one)
    item.update!(low_stock_flagged: true, favorite: true)

    patch archive_item_path(item)

    item.reload
    assert item.archived?
    assert_not item.low_stock_flagged?
    assert_not item.favorite?
    assert_redirected_to items_path
  end

  test "unarchive restores item without restoring favorite" do
    item = items(:one)
    item.update!(archived: true, favorite: false)

    patch unarchive_item_path(item)

    assert_not item.reload.archived?
    assert_not item.favorite?
  end

  test "update_review saves rating and review" do
    item = items(:one)

    patch update_review_item_path(item), params: { item: { rating: 4, review: "よかった" } }

    item.reload
    assert_equal 4, item.rating
    assert_equal "よかった", item.review
    assert_redirected_to item_path(item)
  end

  test "update_review rejects review without rating" do
    item = items(:one)

    patch update_review_item_path(item), params: { item: { rating: "", review: "よかった" } }

    assert_nil item.reload.review
    assert_redirected_to item_path(item)
  end

  test "toggle_low_stock switches item low_stock_flagged state" do
    item = items(:one)
    assert_not item.low_stock_flagged?

    patch toggle_low_stock_item_path(item)
    assert item.reload.low_stock_flagged?

    patch toggle_low_stock_item_path(item)
    assert_not item.reload.low_stock_flagged?
  end

  test "destroy_image removes attached image and redirects to edit page" do
    item = items(:one)
    item.image.attach(
      io: StringIO.new("image"),
      filename: "item.png",
      content_type: "image/png"
    )

    assert item.image.attached?

    delete image_item_path(item)

    assert_redirected_to edit_item_path(item)
    assert_not item.reload.image.attached?
  end

  test "new page has submit loading message" do
    get new_item_path

    assert_response :success
    assert_select "[data-submit-loading]", text: "アイテムを登録しています..."
  end

  test "new page image input supports camera capture" do
    get new_item_path

    assert_response :success
    assert_select "input#item_image_camera[type='file'][name='item[image]'][accept='image/jpeg,image/png'][capture='environment']"
    assert_select "label[for='item_image_camera'].md\\:hidden", text: "カメラを起動"
    assert_select "input#item_image_file[type='file'][name='item[image]'][accept='image/jpeg,image/png']"
    assert_select "label[for='item_image_file'].md\\:hidden", text: "フォルダからアップロード"
    assert_includes response.body, "撮影またはフォルダからアップロードできます"
    assert_includes response.body, "JPEG / PNG、10MB以下の画像を選択してください"
  end

  test "new page has category combobox" do
    get new_item_path

    assert_response :success
    assert_select "input[name='item[new_category_name]'][list='item-category-options']"
    assert_select "datalist#item-category-options option[value='#{categories(:hair_care).name}']"
    assert_includes response.body, "候補から選ぶか、新しいカテゴリ名を入力してください"
  end

  test "edit page shows current category in category combobox" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    get edit_item_path(item)

    assert_response :success
    assert_select "input[name='item[new_category_name]'][value='#{categories(:hair_care).name}']"
  end

  test "edit page has submit loading message" do
    get edit_item_path(items(:one))

    assert_response :success
    assert_select "[data-submit-loading]", text: "アイテム情報を更新しています..."
  end

  test "edit page image input supports camera capture" do
    get edit_item_path(items(:one))

    assert_response :success
    assert_select "input#item_image_camera[type='file'][name='item[image]'][accept='image/jpeg,image/png'][capture='environment']"
    assert_select "label[for='item_image_camera'].md\\:hidden", text: "カメラを起動"
    assert_select "input#item_image_file[type='file'][name='item[image]'][accept='image/jpeg,image/png']"
    assert_select "label[for='item_image_file'].md\\:hidden", text: "フォルダからアップロード"
    assert_includes response.body, "撮影またはフォルダからアップロードできます"
    assert_includes response.body, "JPEG / PNG、10MB以下の画像を選択してください"
  end

  test "new page has brand name field" do
    get new_item_path

    assert_response :success
    assert_select "label[for='item_brand_name']", "ブランド名"
    assert_select "input[name='item[brand_name]'][maxlength='100']"
  end

  test "edit page has brand name field" do
    get edit_item_path(items(:one))

    assert_response :success
    assert_select "label[for='item_brand_name']", "ブランド名"
    assert_select "input[name='item[brand_name]'][maxlength='100']"
  end

  test "new page has an optional review section" do
    get new_item_path

    assert_response :success
    assert_select "button[data-star-rating-star]", count: 5
    assert_select "textarea[name='item[review]']"
  end

  test "edit page has an optional review section with current values" do
    item = items(:one)
    item.update!(rating: 3, review: "まあまあ")

    get edit_item_path(item)

    assert_response :success
    assert_select "input[type='hidden'][name='item[rating]'][value='3']"
    assert_select "textarea[name='item[review]']", text: "まあまあ"
  end

  test "create saves rating and review" do
    assert_difference -> { @user.items.count }, 1 do
      post items_path, params: {
        item: {
          name: "シャンプー",
          price: 1200,
          rating: 5,
          review: "とても良かった"
        }
      }
    end

    item = @user.items.order(:created_at).last
    assert_equal 5, item.rating
    assert_equal "とても良かった", item.review
  end

  test "create fails when review is present without rating" do
    assert_no_difference -> { @user.items.count } do
      post items_path, params: {
        item: {
          name: "シャンプー",
          review: "感想だけ書いた"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "create assigns selected category to item" do
    category = categories(:hair_care)

    assert_difference -> { @user.items.count }, 1 do
      post items_path, params: {
        item: {
          name: "シャンプー",
          price: 1200,
          category_id: category.id
        }
      }
    end

    item = @user.items.order(:created_at).last
    assert_redirected_to items_path
    assert_equal category, item.category
  end

  test "create saves brand name" do
    assert_difference -> { @user.items.count }, 1 do
      post items_path, params: {
        item: {
          name: "シャンプー",
          brand_name: "ものログ製薬",
          price: 1200
        }
      }
    end

    item = @user.items.order(:created_at).last
    assert_redirected_to items_path
    assert_equal "ものログ製薬", item.brand_name
  end

  test "create saves item without brand name" do
    assert_difference -> { @user.items.count }, 1 do
      post items_path, params: {
        item: {
          name: "無印アイテム",
          brand_name: "",
          price: 500
        }
      }
    end

    item = @user.items.order(:created_at).last
    assert_redirected_to items_path
    assert item.brand_name.blank?
  end

  test "create creates new category and assigns it to item" do
    assert_difference -> { @user.categories.count }, 1 do
      assert_difference -> { @user.items.count }, 1 do
        post items_path, params: {
          item: {
            name: "歯ブラシ",
            price: 300,
            new_category_name: "日用品"
          }
        }
      end
    end

    item = @user.items.order(:created_at).last
    assert_redirected_to items_path
    assert_equal "日用品", item.category.name
  end

  test "create rerenders new when new category is invalid" do
    assert_no_difference -> { @user.categories.count } do
      assert_no_difference -> { @user.items.count } do
        post items_path, params: {
          item: {
            name: "長いカテゴリのアイテム",
            price: 300,
            new_category_name: "あ" * 21
          }
        }
      end
    end

    assert_response :unprocessable_content
    assert_includes response.body, "新しいカテゴリ名は20文字以内で入力してください"
  end

  test "update changes category" do
    item = items(:one)
    category = categories(:skin_care)

    patch item_path(item), params: {
      item: {
        name: item.name,
        price: item.price,
        category_id: category.id
      }
    }

    assert_redirected_to items_path
    assert_equal category, item.reload.category
  end

  test "update changes capacity and capacity_unit" do
    item = items(:one)

    patch item_path(item), params: {
      item: {
        name: item.name,
        price: item.price,
        capacity: "500",
        capacity_unit: "ml"
      }
    }

    assert_redirected_to items_path
    item.reload
    assert_equal 500, item.capacity
    assert_equal "ml", item.capacity_unit
  end

  test "show displays capacity and cost per capacity" do
    item = items(:one)
    item.update!(price: 1000, capacity: 500, capacity_unit: "ml")

    get item_path(item)

    assert_response :success
    assert_select "dt", text: "容量"
    assert_includes response.body, "500ml"
    assert_select "dt", text: "容量あたりコスト"
    assert_includes response.body, "2.0円/ml"
  end

  test "show displays unset message when capacity is blank" do
    item = items(:one)

    get item_path(item)

    assert_response :success
    assert_select "dt", text: "容量"
    assert_select "dd", text: "未設定"
  end

  test "update changes brand name" do
    item = items(:one)

    patch item_path(item), params: {
      item: {
        name: item.name,
        brand_name: "ものログコスメ",
        price: item.price
      }
    }

    assert_redirected_to items_path
    assert_equal "ものログコスメ", item.reload.brand_name
  end

  test "update creates new category and assigns it to item" do
    item = items(:one)

    assert_difference -> { @user.categories.count }, 1 do
      patch item_path(item), params: {
        item: {
          name: item.name,
          price: item.price,
          new_category_name: "メイク"
        }
      }
    end

    assert_redirected_to items_path
    assert_equal "メイク", item.reload.category.name
  end

  test "update changes category from category combobox" do
    item = items(:one)
    item.update!(category: categories(:hair_care))
    category = categories(:skin_care)

    patch item_path(item), params: {
      item: {
        name: item.name,
        price: item.price,
        new_category_name: category.name
      }
    }

    assert_redirected_to items_path
    assert_equal category, item.reload.category
  end

  test "update removes category from item when category combobox is blank" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    patch item_path(item), params: {
      item: {
        name: item.name,
        price: item.price,
        new_category_name: ""
      }
    }

    assert_redirected_to items_path
    assert_nil item.reload.category
  end

  test "create assigns existing category from category combobox" do
    category = categories(:hair_care)

    assert_no_difference -> { @user.categories.count } do
      assert_difference -> { @user.items.count }, 1 do
        post items_path, params: {
          item: {
            name: "トリートメント",
            price: 900,
            new_category_name: category.name
          }
        }
      end
    end

    item = @user.items.order(:created_at).last
    assert_redirected_to items_path
    assert_equal category, item.category
  end

  test "create cannot assign another user's category" do
    category = Category.create!(user: users(:two), name: "日用品")

    assert_no_difference -> { @user.items.count } do
      post items_path, params: {
        item: {
          name: "他ユーザーカテゴリのアイテム",
          price: 300,
          category_id: category.id
        }
      }
    end

    assert_response :not_found
  end

  test "index shows item category" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    get items_path

    assert_response :success
    assert_includes response.body, categories(:hair_care).name
  end

  test "index shows item brand name" do
    item = items(:one)
    item.update!(brand_name: "ものログ製薬")

    get items_path

    assert_response :success
    assert_includes response.body, "ものログ製薬"
  end

  test "index paginates items with ten items per page" do
    9.times do |number|
      @user.items.create!(
        name: "ページネーション確認#{number}",
        in_stock: true
      )
    end

    get items_path

    assert_response :success
    assert_select "article", count: 10
    assert_select "a[href='#{items_path(page: 2)}']"

    get items_path(page: 2)

    assert_response :success
    assert_select "article", count: 1
  end

  test "show does not allow accessing another user's item" do
    other_user_item = users(:two).items.create!(name: "他人のアイテム", in_stock: true)

    get item_path(other_user_item)

    assert_response :not_found
  end

  test "show shows item category" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    get item_path(item)

    assert_response :success
    assert_includes response.body, categories(:hair_care).name
  end

  test "show shows item brand name above the item name" do
    item = items(:one)
    item.update!(brand_name: "ものログ製薬")

    get item_path(item)

    assert_response :success
    assert_select "p.truncate.text-emerald-700", text: "ものログ製薬"
    assert response.body.index("ものログ製薬") < response.body.index(">#{item.name}<")
  end

  test "show does not display brand name when it is blank" do
    item = items(:one)
    item.update!(brand_name: "")

    get item_path(item)

    assert_response :success
    assert_select "p.truncate.text-emerald-700", count: 0
  end

  test "show shows an always-editable review form with current rating and review" do
    item = items(:one)
    item.update!(rating: 4, review: "よかった")

    get item_path(item)

    assert_response :success
    assert_select "form[action='#{update_review_item_path(item)}'] input[type='hidden'][name='item[rating]'][value='4']"
    assert_select "form[action='#{update_review_item_path(item)}'] button[data-star-rating-star]", count: 5
    assert_select "form[action='#{update_review_item_path(item)}'] textarea[name='item[review]']", text: "よかった"
  end

  test "edit_review shows a minimal page with just the review form" do
    item = items(:one)
    item.update!(rating: 4, review: "よかった", brand_name: "ものログ製薬")

    get edit_review_item_path(item)

    assert_response :success
    assert_includes response.body, item.name
    assert_select "p.text-emerald-700", text: "ものログ製薬"
    assert_select "form[action='#{update_review_item_path(item)}'] button[data-star-rating-star]", count: 5
    assert_select "form[action='#{update_review_item_path(item)}'] textarea[name='item[review]']", text: "よかった"
  end

  test "show shows a quiet link to archive the item" do
    item = items(:one)

    get item_path(item)

    assert_response :success
    assert_select "a[href='#{confirm_archive_item_path(item)}']", text: "このアイテムを手放す"
  end

  test "update with invalid image rerenders edit page" do
    item = items(:one)

    patch item_path(item), params: {
      item: {
        name: item.name,
        price: item.price,
        image: fixture_file_upload("test_file.txt", "text/plain")
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, "JPEGまたはPNG形式"
  end
end
