require "test_helper"

class ItemTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "by_name returns items whose names partially match" do
    assert_equal [ items(:one) ], Item.by_name("化粧").to_a
  end

  test "by_name returns all items when query is blank" do
    assert_equal Item.order(:id).to_a, Item.by_name(" ").order(:id).to_a
  end

  test "by_category returns items in the selected category" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    assert_equal [ item ], Item.by_category(categories(:hair_care).id.to_s).to_a
  end

  test "by_category returns uncategorized items" do
    items(:one).update!(category: categories(:hair_care))

    assert_equal [ items(:two) ], Item.by_category("uncategorized").to_a
  end

  test "by_category returns all items when category is blank" do
    assert_equal Item.order(:id).to_a, Item.by_category("").order(:id).to_a
  end

  test "assign_category creates and assigns a new category by name" do
    item = items(:one)
    user = users(:one)

    assert_difference -> { user.categories.count }, 1 do
      assert item.assign_category(user, category_id: nil, new_category_name: "日用品", remove_category: nil)
    end
    assert_equal "日用品", item.category.name
  end

  test "assign_category reuses an existing category with the same name" do
    item = items(:one)
    user = users(:one)
    existing = user.categories.create!(name: "日用品")

    assert_no_difference -> { user.categories.count } do
      assert item.assign_category(user, category_id: nil, new_category_name: "日用品", remove_category: nil)
    end
    assert_equal existing, item.category
  end

  test "assign_category returns false and adds error when new category name is invalid" do
    item = items(:one)
    user = users(:one)

    assert_not item.assign_category(user, category_id: nil, new_category_name: "あ" * 21, remove_category: nil)
    assert item.errors[:new_category_name].any?
  end

  test "assign_category removes category when remove_category is set" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    assert item.assign_category(users(:one), category_id: nil, new_category_name: nil, remove_category: "1")
    assert_nil item.category
  end

  test "assign_category assigns category by id scoped to the user" do
    item = items(:one)

    assert item.assign_category(users(:one), category_id: categories(:hair_care).id, new_category_name: nil, remove_category: nil)
    assert_equal categories(:hair_care), item.category
  end

  test "assign_category raises for another user's category id" do
    item = items(:one)
    other_category = users(:two).categories.create!(name: "他ユーザーカテゴリ")

    assert_raises(ActiveRecord::RecordNotFound) do
      item.assign_category(users(:one), category_id: other_category.id, new_category_name: nil, remove_category: nil)
    end
  end

  test "assign_category clears category when nothing is given" do
    item = items(:one)
    item.update!(category: categories(:hair_care))

    assert item.assign_category(users(:one), category_id: nil, new_category_name: nil, remove_category: nil)
    assert_nil item.category
  end

  test "cost_per_capacity divides price by capacity" do
    item = items(:one)
    item.update!(price: 1000, capacity: 500, capacity_unit: "ml")

    assert_equal 2.0, item.cost_per_capacity
  end

  test "cost_per_capacity returns nil when price is blank" do
    item = items(:one)
    item.update!(price: nil, capacity: 500, capacity_unit: "ml")

    assert_nil item.cost_per_capacity
  end

  test "cost_per_capacity returns nil when capacity is blank" do
    item = items(:one)
    item.update!(price: 1000, capacity: nil)

    assert_nil item.cost_per_capacity
  end

  test "item can be saved without image" do
    item = items(:one)

    assert item.valid?
  end

  test "item can be saved without brand name" do
    item = items(:one)
    item.brand_name = nil

    assert item.valid?
  end

  test "item rejects brand name over 100 characters" do
    item = items(:one)
    item.brand_name = "あ" * 101

    assert_not item.valid?
    assert_includes item.errors[:brand_name], "は100文字以内で入力してください"
  end

  test "item can be saved without capacity or capacity_unit" do
    item = items(:one)
    item.capacity = nil
    item.capacity_unit = nil

    assert item.valid?
  end

  test "item rejects capacity of zero or less" do
    item = items(:one)
    item.capacity = 0

    assert_not item.valid?
    assert_includes item.errors[:capacity], "は0より大きい値にしてください"
  end

  test "item rejects capacity_unit outside the allowed list" do
    item = items(:one)
    item.capacity_unit = "L"

    assert_not item.valid?
    assert_includes item.errors[:capacity_unit], "は一覧にありません"
  end

  test "item accepts png image" do
    item = items(:one)
    item.image.attach(
      fixture_file_upload("test_image.png", "image/png")
    )

    assert item.valid?
  end

  test "item image has display variants" do
    variants = Item.reflect_on_attachment(:image).named_variants

    assert_equal [ 160, 160 ], variants[:thumbnail].transformations[:resize_to_fill]
    assert_equal :webp, variants[:thumbnail].transformations[:format]
    assert_equal [ 512, 512 ], variants[:preview].transformations[:resize_to_fill]
    assert_equal :webp, variants[:preview].transformations[:format]
  end

  test "active storage uses vips for image processing" do
    assert_equal :vips, Rails.application.config.active_storage.variant_processor
  end

  test "item rejects non image file" do
    item = items(:one)
    item.image.attach(
      fixture_file_upload("test_file.txt", "text/plain")
    )

    assert_not item.valid?
    assert_includes item.errors[:image], "はJPEGまたはPNG形式でアップロードしてください"
  end

  test "item rejects image over 10 megabytes" do
    item = items(:one)
    item.image.attach(
      io: StringIO.new("a" * (10.megabytes + 1)),
      filename: "large.png",
      content_type: "image/png"
    )

    assert_not item.valid?
    assert_includes item.errors[:image], "は10MB以下にしてください"
  end
end
