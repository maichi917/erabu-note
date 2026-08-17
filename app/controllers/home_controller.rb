class HomeController < ApplicationController
  before_action :authenticate_user!

  IN_USE_DISPLAY_LIMIT = 4

  def show
    in_use_usage_logs = current_user.usage_logs
                                     .in_use
                                     .includes(:item)
                                     .order(started_at: :desc)
    @in_use_usage_logs_count = in_use_usage_logs.count
    @in_use_usage_logs = in_use_usage_logs.limit(IN_USE_DISPLAY_LIMIT)

    @good_usage_logs = current_user.usage_logs
                                    .rated
                                    .where(rating: 4..5)
                                    .includes(:item)
                                    .order(rating: :desc, created_at: :desc)
                                    .limit(3)

    @bad_usage_logs = current_user.usage_logs
                                   .rated
                                   .where(rating: 1..2)
                                   .includes(:item)
                                   .order(rating: :asc, created_at: :desc)
                                   .limit(3)
  end
end
