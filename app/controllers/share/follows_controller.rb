class Share::FollowsController < Share::BaseController
  before_action :set_user

  def create
    nickname = params[:nickname].to_s.strip
    current_user.update(name: nickname) if nickname.present?
    current_user.follow!(@user)
    redirect_to share_user_path(@user), status: :see_other
  end

  def destroy
    current_user.unfollow!(@user)
    redirect_to share_user_path(@user), status: :see_other
  end

  private

  def set_user
    @user = User.visible_to(current_user).where.not(id: current_user.id).find(params[:user_id])
  end
end
