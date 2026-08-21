class Users::RegistrationsController < Devise::RegistrationsController
  before_action :reject_guest, only: %i[edit update]

  private

  # ゲストがメールアドレスを変更すると guest? の判定が外れ、
  # 定期削除（guest:cleanup）の対象から漏れてしまうため、アカウント編集を行えないようにする
  def reject_guest
    return unless current_user&.guest?

    redirect_to root_path, alert: "ゲストではアカウント情報を変更できません"
  end

  # LINE連携済みユーザーは、本人の知らない自動生成パスワードを持っているため、
  # 現在のパスワード確認をスキップして名前・メールアドレスを更新できるようにする
  def update_resource(resource, params)
    return super unless resource.line_linked?

    params = params.dup
    params.delete(:current_password)
    params.delete(:password) if params[:password].blank?
    params.delete(:password_confirmation) if params[:password_confirmation].blank?

    resource.update(params)
  end
end
