class HomeController < ApplicationController
  before_action :authenticate_user!

  def show
    @in_use_usage_logs = current_user.usage_logs
                                      .in_use
                                      .includes(:item)
                                      .order(started_at: :desc)
  end
end
