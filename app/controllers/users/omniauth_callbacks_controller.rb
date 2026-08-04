class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    auth = request.env["omniauth.auth"]
    user = User.find_by(line_user_id: auth.uid)

    if user
      sign_in user, event: :authentication
      redirect_to after_sign_in_path_for(user), notice: "LINEアカウントでログインしました"
    else
      user = User.new(
        name: auth.info.name.presence || "LINEユーザー",
        email: "line-#{auth.uid}@line.invalid",
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
end
