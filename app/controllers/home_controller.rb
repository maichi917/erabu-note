class HomeController < ApplicationController
  before_action :authenticate_user!

  def show
    @in_use_usage_logs = current_user.usage_logs
                                      .in_use
                                      .includes(:item)
                                      .order(started_at: :desc)

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
