class ApplicationController < ActionController::Base
  protect_from_forgery
  trusted

  def current_user
    @user ||= User.first || User.create
  end
end
