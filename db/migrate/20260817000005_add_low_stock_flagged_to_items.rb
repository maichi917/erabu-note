class AddLowStockFlaggedToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :low_stock_flagged, :boolean, default: false, null: false
  end
end
