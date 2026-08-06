class Users::RegistrationsController < Devise::RegistrationsController
  private

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
