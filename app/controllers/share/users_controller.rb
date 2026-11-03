class Share::UsersController < Share::BaseController
  def show
    @user = User.visible_to(current_user).find(params[:id])
    return redirect_to share_mypage_path if @user == current_user

    @items = @user.items.shared.order(shared_at: :desc).with_attached_image
  end
end
