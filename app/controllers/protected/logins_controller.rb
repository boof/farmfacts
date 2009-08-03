class Protected::LoginsController < Protected::Base

  before_filter :authorized?, :except => [:index, :show]

  before_filter :assign_target
  before_filter :assign_login, :except => [:index]

  def index
    @logins = @target.find :all
    set_title 'logins'
  end
  def show
    set_title 'logins'
  end
  def new
    set_title 'logins'
    render :action => :new
  end
  def create
    if @login.save
      redirect_to return_uri || protected_login_path(@login)
    else
      new
    end
  end
  def edit
    set_title 'protected.logins.edit', :actions, :name => @login.name
    render :action => :edit
  end
  def update
    if @login.save
      redirect_to return_uri || protected_login_path(@login)
    else
      edit
    end
  end
  def destroy
    @login.destroy
    redirect_to return_uri || protected_logins_path
  end

  protected

    def group
      @group ||= Group.find_by_id params[:group_id]
    end
    def assign_target
      @target = group ? group.memberships : Login
    end
    def assign_login
      @login = @target.find_or_initialize_by_id params[:id]
      @login.attributes = params[:login] if params[:login]
    end
    def authorized?
      visitor.administrator? or visitor.leads? @group
    end

end
