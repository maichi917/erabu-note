class AddShareSeenAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :share_seen_at, :datetime
  end
end
