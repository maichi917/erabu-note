class AddRatingAndReviewToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :rating, :integer
    add_column :items, :review, :text
  end
end
