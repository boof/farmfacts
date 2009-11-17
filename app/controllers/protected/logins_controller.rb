class Protected::LoginsController < Protected::Base

  before_filter :authorized?, :except => [:index, :show]
  before_filter :assign_searcher, :except => :index
  before_filter :set_title

  def index
    @logins, @searcher = Login.search params[:login]
  end
  def show id = param(:id),
    login = Login.find(id, :include => {:roles => :group})

    @login = login
  end
  def new attributes = param(:login, {}),
      login = Login.new(attributes)

    @login = login
    return :new
  end
  def create attributes = param(:login),
      login = Login.new(attributes)

    if login.save
      redirect_to return_uri || protected_login_path(login)
    else
      render new(attributes, login)
    end
  end
  def edit id = param(:id),
      login = Login.find(id)

    @login = login
    return :edit
  end
  def update id = param(:id), attributes = param(:login),
      login = Login.find(id).tap { |this| this.attributes = attributes }

    if login.save
      redirect_to return_uri || protected_login_path(login)
    else
      render edit(id, login)
    end
  end
  def destroy id = param(:id),
      login = Login.find(id)

    login.destroy
    redirect_to return_uri || protected_logins_path
  end

  protected

    def set_title
      super 'logins'
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
