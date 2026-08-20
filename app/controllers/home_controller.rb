class HomeController < ApplicationController
  before_action :authenticate_user!

  LOW_STOCK_DISPLAY_LIMIT = 4
  UNREVIEWED_DISPLAY_LIMIT = 6

  def show
    low_stock_items = current_user.items.visible.where(low_stock_flagged: true).order(updated_at: :desc)
    @low_stock_items_count = low_stock_items.count
    @low_stock_items = low_stock_items.limit(LOW_STOCK_DISPLAY_LIMIT)

    unreviewed_items = current_user.items.visible.where(rating: nil).order(created_at: :desc)
    @unreviewed_items_count = unreviewed_items.count
    @unreviewed_items = unreviewed_items.limit(UNREVIEWED_DISPLAY_LIMIT)

    @good_items = current_user.items.visible
                               .where(rating: 4..5)
                               .order(rating: :desc, updated_at: :desc)
                               .limit(3)

    @bad_items = current_user.items.visible
                              .where(rating: 1..2)
                              .order(rating: :asc, updated_at: :desc)
                              .limit(3)
  end
end
