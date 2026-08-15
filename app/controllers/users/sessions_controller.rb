class Users::SessionsController < Devise::SessionsController
  def guest_sign_in
    if current_user&.guest?
      redirect_to after_sign_in_path_for(current_user)
      return
    end

    guest = User.create_guest!
    guest.seed_guest_sample_data!
    sign_in guest, event: :authentication
    redirect_to after_sign_in_path_for(guest), notice: "ゲストとしてログインしました"
  end
end
