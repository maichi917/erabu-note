class Share::NicknamesController < Share::BaseController
  before_action :reject_guest

  def edit
  end

  def update
    if current_user.update(name: params.dig(:user, :name).to_s.strip)
      redirect_to share_mypage_path, notice: "ニックネームを変更しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def reject_guest
    return unless current_user.guest?

    redirect_to share_mypage_path, alert: "ゲストではニックネームを変更できません"
  end
end
