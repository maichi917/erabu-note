class StaticPagesController < ApplicationController
  def top
    redirect_to home_path if user_signed_in?
  end

  def terms; end

  def privacy; end

  def contact; end
end
