class HomeController < ApplicationController
  before_action :authenticate_user!

  LOW_STOCK_DISPLAY_LIMIT = 4
  UNREVIEWED_DISPLAY_LIMIT = 6

  def show
    low_stock_items = current_user.items.visible.low_stock.order(updated_at: :desc)
    @low_stock_items_count = low_stock_items.count
    @low_stock_items = low_stock_items.limit(LOW_STOCK_DISPLAY_LIMIT)

    unreviewed_items = current_user.items.visible.unreviewed.order(created_at: :desc)
    @unreviewed_items_count = unreviewed_items.count
    @unreviewed_items = unreviewed_items.limit(UNREVIEWED_DISPLAY_LIMIT)

    @good_items = current_user.items.visible
                               .highly_rated
                               .order(rating: :desc, updated_at: :desc)
                               .limit(3)

    @bad_items = current_user.items.visible
                              .poorly_rated
                              .order(rating: :asc, updated_at: :desc)
                              .limit(3)
  end
end
