class Share::BookmarksController < Share::BaseController
  before_action :set_item

  def create
    current_user.bookmark!(@item)
    redirect_back_or_to share_timeline_path, status: :see_other
  end

  def destroy
    current_user.unbookmark!(@item)
    redirect_back_or_to share_timeline_path, status: :see_other
  end

  private

  def set_item
    @item = Item.shared_for(current_user).find(params[:item_id])
  end
end
