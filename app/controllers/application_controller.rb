class ApplicationController < ActionController::Base; protected

  protect_from_forgery
  helper :all
  filter_parameter_logging :password, :password_confirmation

  def forbidden!
    render :text => '403 Forbidden', :status => '403 Forbidden'
  end
  around_filter Visit

  def locales
    I18n.available_locales.map { |sym| sym.to_s }
  end
  include LanguageNegotiation::Extension

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

  def param(key, *default)
    params.fetch key.to_s, *default
  end

end
