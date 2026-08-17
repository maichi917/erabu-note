class ReplaceStockQuantityWithInStockOnItems < ActiveRecord::Migration[7.1]
  def change
    remove_column :items, :stock_quantity, :integer
    add_column :items, :in_stock, :boolean, default: true, null: false
  end
end
