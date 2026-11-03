class AddSharingToItems < ActiveRecord::Migration[8.1]
  def change
    # 初期値は「シェアしない」。既存の感想が勝手に他のユーザーに見えないようにする
    add_column :items, :shared, :boolean, default: false, null: false
    # シェアした日時、またはシェア中に感想を更新した日時。タイムラインの並び順に使う
    add_column :items, :shared_at, :datetime
  end
end
