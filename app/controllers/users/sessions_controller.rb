class Users::SessionsController < Devise::SessionsController
  # ログイン中にゲストログインを実行しても、既存のセッションを置き換えないようにする。
  # Deviseの標準ガードだが、new/create にしか適用されないため、独自アクションには自分で指定する
  before_action :require_no_authentication, only: [ :guest_sign_in ]

  def guest_sign_in
    guest = User.create_guest!
    guest.seed_guest_sample_data!
    sign_in guest, event: :authentication
    redirect_to after_sign_in_path_for(guest), notice: "ゲストとしてログインしました"
  end
end
