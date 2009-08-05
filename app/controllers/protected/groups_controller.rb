class Protected::GroupsController < Protected::Base

  before_filter :authorized?, :except => [:index, :show]

  before_filter :assign_group, :except => [:index, :show]

  def index
    @groups = Group.find :all
    set_title 'groups'
  end
  def show
    @group = Group.find params[:id], :include => {:roles => {:login => :roles}}
    @roles = @group.roles.sort_by { |role| "#{ role.login.last_name }#{ role.login.first_name }" }
    @logins = Login.find :all, :include => {:roles => :group}

    set_title 'groups'
  end
  def new
    set_title 'groups'
    render :action => :new
  end
  def create
    if @group.save
      redirect_to return_uri || protected_group_path(@group)
    else
      new
    end
  end
  def edit
    set_title 'groups'
    render :action => :edit
  end
  def update
    if @group.save
      redirect_to return_uri || protected_group_path(@group)
    else
      edit
    end
  end
  def destroy
    @group.destroy
    redirect_to return_uri || protected_groups_path
  end

  protected

    def assign_group
      @group = Group.find_or_initialize_by_id params[:id]
      @group.attributes = params[:group] if params[:group]
    end
    def authorized?
      visitor.administrator? or begin
        %w[ edit update ].include? action_name and
        visitor.leads? @group
      end
    end

end
