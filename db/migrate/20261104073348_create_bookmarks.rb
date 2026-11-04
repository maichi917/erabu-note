class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :item, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :bookmarks, [ :user_id, :item_id ], unique: true
  end
end
