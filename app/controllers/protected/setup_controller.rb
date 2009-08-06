class Protected::SetupController < ApplicationController

  layout false

  def new_user
    set_title = 'admin.setup.new_user'
    render :action => :new_user
  end
  def create_user
    visitor.attributes = params[:login]
    visitor.save_as_admin(true) ? redirect_to(login_path) : new_user
  end

  protected

    def possible?
      render :nothing => true if Login.exists?
    end
    before_filter :possible?

end
