class Share::MypagesController < Share::BaseController
  def show
    @items = current_user.items.shared.order(shared_at: :desc).with_attached_image
  end
end
