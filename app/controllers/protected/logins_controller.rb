class Protected::LoginsController < Protected::Base

  before_filter :authorized?, :except => [:index, :show]
  before_filter :assign_searcher, :assign_login, :except => :index

  def index
    @logins, @searcher = Login.search params[:login]
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
    if save_login
      redirect_to return_uri || protected_login_path(@login)
    else
      new
    end
  end
  def edit
    set_title 'logins'
    render :action => :edit
  end
  def update
    if save_login
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

    def save_login
      @login.save_as_admin params[:administrator]
    end

    def group
      @group ||= Group.find params[:group_id] unless params[:group_id].blank?
    end
    def assign_searcher
      @searcher = Login.new
    end
    def assign_login
      @login = Login.find_or_initialize_by_id params[:id],
          :include => {:roles => :group}
      @login.attributes = params[:login] if params[:login]
    end
    def authorized?
      return if visitor.admin?
      return if group and visitor.leads? group and not params[:administrator]

      forbidden!
    end

end
