class ApplicationController < ActionController::Base; protected

  protect_from_forgery
  helper :all
  filter_parameter_logging :password, :password_confirmation

  around_filter Visit

  around_filter LocaleNegotiation
  def set_title(title, *namespace)
    options   = namespace.extract_options!
    namespace = namespace.map { |n| n.to_s } * '.'
    namespace = 'titles' if namespace.blank?

    @title = translate :"#{ namespace }.#{ title }", options
  end
  def title
    @title ||= translate :'titles.default'
  end
  helper_method :title

end
