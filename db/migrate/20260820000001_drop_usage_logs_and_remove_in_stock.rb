class DropUsageLogsAndRemoveInStock < ActiveRecord::Migration[8.1]
  def change
    remove_column :items, :in_stock, :boolean, default: true, null: false

    drop_table :usage_logs do |t|
      t.datetime "created_at", null: false
      t.datetime "finished_at"
      t.uuid "item_id", null: false
      t.integer "rating"
      t.text "review"
      t.datetime "started_at"
      t.datetime "updated_at", null: false
      t.uuid "user_id", null: false
      t.index [ "item_id", "finished_at" ], name: "index_usage_logs_on_item_id_and_finished_at"
      t.index [ "item_id" ], name: "index_usage_logs_on_item_id"
      t.index [ "item_id" ], name: "index_usage_logs_on_item_id_where_in_use", unique: true, where: "(finished_at IS NULL)"
      t.index [ "user_id", "finished_at" ], name: "index_usage_logs_on_user_id_and_finished_at"
      t.index [ "user_id" ], name: "index_usage_logs_on_user_id"
      t.foreign_key :items
      t.foreign_key :users
    end
  end
end
