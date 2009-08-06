class Visit

  CLASS, KEY = ::Login, :visitor
  @instances = {}

  def self.filter(controller)
    current_instance new(controller) do |instance|
      yield
      controller.session[KEY] = instance.visitor.id
    end
  end

  def self.leave
    instance { leave }
  end
  def self.return_uri
    instance { return_uri }
  end
  def self.current_uri(suffix = '')
    instance { current_uri suffix }
  end
  def self.visitor
    instance { visitor }
  end

  def leave; @visitor = Login.new end
  def return_uri; Rack::Utils.unescape params[:return_uri] if params[:return_uri] end
  def current_uri(suffix = '')
    @base_uri ||= begin
      params = request.query_string.split '&'
      params.any? { |param| params.delete param if param[0, 10] == 'return_uri' }
      params = "?#{ params.join '&' }" unless params.empty?

      "#{ request.request_uri.split('?', 2).first }#{ params }"
    end

    Rack::Utils.escape "#{ @base_uri }#{ suffix }"
  end
  attr_reader :visitor

  protected
  def self.current_instance(instance)
    @instances[ Thread.current ] = instance
    yield instance
  ensure
    @instances[ Thread.current ] = nil
  end
  def self.instance(&block)
    instance = @instances[ Thread.current ] || raise
    instance.instance_eval(&block)
  end

  def initialize(controller)
    @controller = controller
    authenticate_visitor
  end
  delegate :cookies, :params, :request, :session, :to => :@controller

  def session?
    cookies[ ActionController::Base.session_options[:key] ]
  end
  def authenticate_visitor
    credentials = params[KEY]
    credentials ||= session[KEY] if session?

    @visitor = CLASS.authenticate credentials
  end

  module ControllerMethods
    def self.extended(base)
      base.delegate :leave, :return_uri, :visitor, :current_uri, :to => Visit
      base.hide_action :leave, :return_uri, :current_uri, :visitor
      base.helper_method :return_uri, :current_uri, :visitor
    end
    def anonymous(opts = {})
      before_filter(opts) { |ctrl|
          ctrl.visitor.authenticated? or yield ctrl }
    end
    def authenticated(opts = {})
      before_filter(opts) { |ctrl|
          ctrl.visitor.authenticated? and yield ctrl }
    end
  end
  ApplicationController.extend Visit::ControllerMethods

end
