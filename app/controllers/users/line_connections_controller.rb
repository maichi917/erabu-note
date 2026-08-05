class Users::LineConnectionsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    current_user.update!(line_user_id: nil, line_access_token: nil)
    redirect_to edit_user_registration_path, notice: "LINE連携を解除しました"
  end
end
