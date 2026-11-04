class Share::UsersController < Share::BaseController
  before_action :set_user

  def show
    return redirect_to share_mypage_path if @user == current_user

    @items = @user.items.shared.order(shared_at: :desc).with_attached_image
  end

  def following
    @title = "フォロー"
    @users = @user.visible_following(current_user)
    render :follows
  end

  def followers
    @title = "フォロワー"
    @users = @user.visible_followers(current_user)
    render :follows
  end

  private

  def set_user
    @user = User.visible_to(current_user).find(params[:id])
  end
end
