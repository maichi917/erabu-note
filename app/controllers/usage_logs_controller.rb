class UsageLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_usage_log, only: %i[show edit update]
  before_action :set_filter_params, only: %i[reviews]

  def show
  end

  def edit
  end

  def reviews
    @page_title = "レビュー"
    @selected_rating = params[:rating].to_s
    @items = current_user.items
                         .where.not(rating: nil)
                         .by_rating(@selected_rating)
                         .by_name(@search_query)
                         .by_category(@selected_category_id)
                         .order(updated_at: :desc)
                         .page(params[:page])
  end

  def update
    if @usage_log.update(usage_log_params)
      redirect_to item_path(@usage_log.item), notice: "評価とレビューを保存しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_usage_log
    @usage_log = current_user.usage_logs.includes(:item).find(params[:id])
  end

  def usage_log_params
    params.require(:usage_log).permit(:rating, :review)
  end
end
