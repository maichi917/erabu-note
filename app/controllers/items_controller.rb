class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_categories, only: %i[new create edit update]
  before_action :set_filter_params, only: %i[index in_use used_up]
  before_action :set_item, only: %i[show edit update destroy destroy_image toggle_favorite
                                    start_using finish_using toggle_stock toggle_low_stock]

  def index
    @items = current_user.items.visible.includes(:category).order(created_at: :desc)
    @selected_status = params[:status].to_s
    @selected_favorite = params[:favorite].to_s
    @items = @items.by_name(@search_query)
                   .by_category(@selected_category_id)
    @items = @items.where(favorite: true) if @selected_favorite == "1"

    in_use_item_ids = current_user.usage_logs.in_use.select(:item_id)
    case @selected_status
    when "available"
      @items = @items.where(in_stock: true).where.not(id: in_use_item_ids)
    when "in_use"
      @items = @items.where(id: in_use_item_ids)
    when "out_of_stock"
      @items = @items.where(in_stock: false).where.not(id: in_use_item_ids)
    end

    @page_title = "アイテム"
    @items = @items.page(params[:page])
  end

  def in_use
    @page_title = "使用中アイテム"
    @usage_logs = current_user.usage_logs
                              .in_use
                              .by_item_name(@search_query)
                              .by_item_category(@selected_category_id)
                              .includes(:item)
                              .order(started_at: :desc)
                              .page(params[:page])
  end

  def used_up
    @page_title = "使い切り"
    @selected_rating = params[:rating].to_s
    @selected_rating_status = params[:rating_status].to_s
    @selected_review_status = params[:review_status].to_s
    @usage_logs = current_user.usage_logs
                              .finished
                              .by_item_name(@search_query)
                              .by_item_category(@selected_category_id)
                              .by_rating(@selected_rating)
                              .by_rating_status(@selected_rating_status)
                              .by_review_status(@selected_review_status)
                              .latest_per_item
                              .includes(:item)
                              .order(finished_at: :desc)
                              .page(params[:page])
    @used_up_counts_by_item_id = current_user.usage_logs
                                             .finished
                                             .group(:item_id)
                                             .count
  end

  # 検索欄のオートコンプリート候補（アイテム名）をJSONで返す
  def autocomplete
    query = params[:q].to_s.strip
    names =
      if query.length >= 2
        current_user.items.by_name(query).order(:name).distinct.limit(10).pluck(:name)
      else
        []
      end

    render json: names
  end

  def new
    @item = current_user.items.new
  end

  def create
    @item = current_user.items.build(item_params)

    if assign_category && @item.save
      redirect_to items_path, notice: "アイテムが作成されました。"
    else
      set_categories
      flash.now[:alert] = "アイテムの作成に失敗しました。"
      render :new, status: :unprocessable_content
    end
  end

  def show
  end

  def edit
  end

  def update
    @item.assign_attributes(item_params)

    if assign_category && @item.save
      redirect_to items_path, notice: "アイテム情報を更新しました"
    else
      set_categories
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @item.destroy!
    redirect_to items_path, notice: "アイテムが削除されました"
  end

  def destroy_image
    @item.image.purge
    redirect_to edit_item_path(@item), notice: "画像を削除しました"
  end

  def toggle_favorite
    @item.update!(favorite: !@item.favorite?)

    notice = @item.favorite? ? "お気に入りに追加しました" : "お気に入りを解除しました"
    redirect_back fallback_location: item_path(@item), notice: notice
  end

  def start_using
    if @item.using?
      redirect_to items_path, alert: "すでに使用中です"
      return
    end

    unless @item.in_stock?
      redirect_to items_path, alert: "在庫がありません"
      return
    end

    @item.start_using!(current_user, params[:started_at], started_at_unknown: params[:started_at_unknown].present?)
    redirect_to in_use_items_path, notice: "使用を開始しました"
  end

  def finish_using
    usage_log =
      if params[:usage_log_id].present?
        @item.usage_logs.in_use.find_by(id: params[:usage_log_id])
      else
        @item.current_usage_log
      end

    if usage_log.blank?
      redirect_to in_use_items_path, alert: "使用中のアイテムがありません"
      return
    end

    @item.finish_using!(params[:finished_at])

    redirect_to edit_usage_log_path(usage_log), notice: "アイテムを使い切りました🎉"
  end

  def toggle_stock
    @item.update!(in_stock: !@item.in_stock?)

    redirect_back fallback_location: items_path
  end

  def toggle_low_stock
    @item.update!(low_stock_flagged: !@item.low_stock_flagged?)

    redirect_back fallback_location: items_path
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :brand_name, :price, :favorite, :memo, :image, :capacity, :capacity_unit)
  end

  def assign_category
    @item.assign_category(
      current_user,
      category_id: params.dig(:item, :category_id),
      new_category_name: params.dig(:item, :new_category_name),
      remove_category: params.dig(:item, :remove_category)
    )
  end
end
