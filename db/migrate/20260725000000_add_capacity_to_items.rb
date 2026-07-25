class AddCapacityToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :capacity, :decimal, precision: 8, scale: 2
    add_column :items, :capacity_unit, :string
  end
end
