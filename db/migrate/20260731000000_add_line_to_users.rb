class AddLineToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :line_user_id, :string
    add_column :users, :line_access_token, :string
    add_index :users, :line_user_id, unique: true
  end
end
