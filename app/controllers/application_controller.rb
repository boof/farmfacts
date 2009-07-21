class ApplicationController < ActionController::Base

  filter_parameter_logging :password, :password_confirmation
  helper :all
  protect_from_forgery

end
