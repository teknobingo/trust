class ApplicationController < ActionController::Base
  protect_from_forgery
  trusted

  attr_accessor :current_user

end
