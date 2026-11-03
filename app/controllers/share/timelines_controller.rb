class Share::TimelinesController < Share::BaseController
  def show
    @items = current_user.timeline_items.includes(:user).with_attached_image
                         .order(shared_at: :desc).page(params[:page])
    # 開いたら、赤い点を消す
    current_user.update_column(:share_seen_at, Time.current)
  end
end
