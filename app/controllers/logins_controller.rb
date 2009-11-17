class LoginsController < ApplicationController

  def new
    set_title 'logins.new', :actions
    render :action => :new, :status => 401
  end

  def create
    if visitor.authenticated?
      redirect_to return_uri || login_path(visitor)
    else
      new
    end
  end

  anonymous :except => [:new, :create] do |ctrl|
    ctrl.instance_eval do
      return_uri = request.request_uri unless request.post?
      redirect_to new_login_path(:return_uri => return_uri)
    end
  end
  layout :choose_layout

  def show
    set_title 'logins.show', :actions
  end

  def edit
    set_title 'logins.edit'
    render :action => :edit
  end
  def update
    visitor.attributes = params[:login]

    if visitor.save
      redirect_to login_path(visitor)
    else
      edit
    end
  end

  def destroy
    leave and redirect_to '/'
  end

  protected

    def choose_layout
      visitor.authenticated?? 'protected' : false
    end

end
