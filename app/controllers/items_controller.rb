class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_categories, only: %i[new create edit update]
  before_action :set_filter_params, only: %i[index reviews]
  before_action :set_item, only: %i[show edit update destroy destroy_image toggle_favorite
                                    toggle_low_stock confirm_archive archive unarchive edit_review update_review]
  # 手放したアイテムで、フラグ（よく使うもの・なくなりそう）の切り替えと「手放す」操作をできないようにする
  before_action :reject_archived_item, only: %i[toggle_favorite toggle_low_stock confirm_archive archive]

  def index
    @scope = params[:scope].to_s
    @favorite_filter = params[:favorite] == "1"
    @low_stock_filter = params[:low_stock] == "1"
    @unreviewed_filter = params[:unreviewed] == "1"

    @items = @scope == "archived" ? current_user.items.archived : current_user.items.visible
    @items = @items.favorites if @favorite_filter
    @items = @items.low_stock if @low_stock_filter
    @items = @items.unreviewed if @unreviewed_filter

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

  # 感想を振り返る画面（評価がついているアイテムの一覧）
  def reviews
    @page_title = "レビュー"
    @selected_rating = params[:rating].to_s
    @items = current_user.items
                         .reviewed
                         .by_rating(@selected_rating)
                         .by_name(@search_query)
                         .by_category(@selected_category_id)
                         .order(updated_at: :desc)
                         .page(params[:page])
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

  def confirm_archive
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

    notice = @item.low_stock_flagged? ? "なくなりそうに追加しました" : "なくなりそうから外しました"
    redirect_back fallback_location: items_path, notice: notice
  end

  def edit_review
  end

  def update_review
    was_unreviewed = @item.rating.blank?

    if @item.update(review_params)
      notice = was_unreviewed ? "感想を書きました" : "感想を更新しました"
      destination =
        case params[:return_to]
        when "confirm_archive" then confirm_archive_item_path(@item)
        when "edit_review" then edit_review_item_path(@item)
        else item_path(@item)
        end

      redirect_to destination, notice: notice
    else
      redirect_to @item, alert: @item.errors.full_messages.to_sentence
    end
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  # 手放したアイテムなら、ここで処理を止めて詳細画面へ戻す
  def reject_archived_item
    return unless @item.archived?

    redirect_to item_path(@item), alert: "手放したアイテムは変更できません"
  end

  def item_params
    params.require(:item).permit(:name, :brand_name, :price, :memo, :image, :capacity, :capacity_unit,
                                  :rating, :review)
  end

  def review_params
    params.require(:item).permit(:rating, :review)
  end

  def assign_category
    @item.assign_category(current_user, new_category_name: params.dig(:item, :new_category_name))
  end
end
