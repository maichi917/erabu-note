class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :item

  validates :item_id, uniqueness: { scope: :user_id }
end
