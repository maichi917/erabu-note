# 他のユーザーのプロフィール。その人がシェアしている感想だけを並べる
class Share::UsersController < Share::BaseController
  before_action :reject_guest

  def show
    @user = User.find(params[:id])
    return redirect_to share_mypage_path if @user == current_user

    @items = @user.items.shared.order(shared_at: :desc).with_attached_image
  end

  private

  def reject_guest
    return unless current_user.guest?

    redirect_to share_mypage_path, alert: "他のユーザーのページは、新規登録すると見られます"
  end
end
