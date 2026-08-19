class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_categories, only: %i[new create edit update]
  before_action :set_filter_params, only: %i[index]
  before_action :set_item, only: %i[show edit update destroy destroy_image toggle_favorite
                                    toggle_low_stock archive unarchive edit_review update_review]

  def index
    @selected_status = params[:status].to_s
    @items =
      case @selected_status
      when "favorite"
        current_user.items.visible.where(favorite: true)
      when "low_stock"
        current_user.items.visible.where(low_stock_flagged: true)
      when "archived"
        current_user.items.archived
      else
        current_user.items.visible
      end

    @items = @items.includes(:category)
                   .order(created_at: :desc)
                   .by_name(@search_query)
                   .by_category(@selected_category_id)

    @page_title = "アイテム"
    @items = @items.page(params[:page])
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

    notice = @item.favorite? ? "よく使うものに追加しました" : "よく使うものから外しました"
    redirect_back fallback_location: item_path(@item), notice: notice
  end

  def archive
    @item.archive!
    redirect_to items_path, notice: "手放したアイテムに移動しました"
  end

  def unarchive
    @item.unarchive!
    redirect_back fallback_location: items_path, notice: "リストに戻しました"
  end

  def toggle_low_stock
    @item.update!(low_stock_flagged: !@item.low_stock_flagged?)

    redirect_back fallback_location: items_path
  end

  def edit_review
  end

  def update_review
    if @item.update(review_params)
      redirect_to @item, notice: "感想を更新しました"
    else
      redirect_to @item, alert: @item.errors.full_messages.to_sentence
    end
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :brand_name, :price, :favorite, :memo, :image, :capacity, :capacity_unit,
                                  :rating, :review)
  end

  def review_params
    params.require(:item).permit(:rating, :review)
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
