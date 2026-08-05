class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    auth = request.env["omniauth.auth"]

    if current_user
      link_line_to_current_user(auth)
      return
    end

    user = User.find_by(line_user_id: auth.uid)

    if user
      sign_in user, event: :authentication
      redirect_to after_sign_in_path_for(user), notice: "LINEアカウントでログインしました"
    else
      user = User.new(
        name: auth.info.name.presence || "LINEユーザー",
        email: "line-#{auth.uid}@#{User::LINE_PLACEHOLDER_EMAIL_DOMAIN}",
        password: Devise.friendly_token[0, 20],
        line_user_id: auth.uid,
        line_access_token: auth.credentials.token
      )

      if user.save
        sign_in user, event: :authentication
        redirect_to after_sign_in_path_for(user), notice: "LINEアカウントで新規登録しました"
      else
        redirect_to new_user_session_path, alert: "LINEアカウントでの登録に失敗しました"
      end
    end
  end

  private

  def link_line_to_current_user(auth)
    if User.exists?(line_user_id: auth.uid)
      redirect_to edit_user_registration_path,
                  alert: "このLINEアカウントは、すでに別のアカウントと連携しています。こちらのアカウントに連携したい場合は、まず連携済みのアカウントでログインし、「LINE連携を解除する」を行ってから、もう一度お試しください。"
      return
    end

    current_user.update!(line_user_id: auth.uid, line_access_token: auth.credentials.token)
    redirect_to edit_user_registration_path, notice: "LINEアカウントと連携しました"
  end
end
