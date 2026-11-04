class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows, id: :uuid do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :followed, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    # 同じ人を2回フォローできないようにする
    add_index :follows, [ :follower_id, :followed_id ], unique: true
  end
end
