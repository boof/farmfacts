class Protected::RolesController < Protected::Base

  before_filter :correct_method?
  before_filter :assign_group, :except => :administers
  before_filter :authorized?

  def destroy(redirect = true)
    role = Role.find_by_login_id_and_group_id params[:login_id], @group.id
    role.destroy if role
      
    redirect_to return_uri if redirect
  end
  def administers
    login = Login.find params[:login_id]
    role = AdministeringRole.new :login => login

    role.save!

    redirect_to return_uri
  end
  def belongs_to
    destroy false

    login = Login.find params[:login_id]
    role = login.memberships.new :group => @group

    role.save!

    redirect_to return_uri
  end
  def leads
    destroy false

    login = Login.find params[:login_id]
    role = login.leaderships.new :group => @group

    role.save!

    redirect_to return_uri
  end

  protected
  def correct_method?
    !request.get?
  end
  def assign_group
    @group = Group.find_by_id params[:group_id]
  end
  def authorized?
    authorized = case action_name
    when 'administers'; visitor.admin?
    when 'belongs_to', 'leads', 'destroy'
      visitor.admin? or visitor.leader_of? @group
    end

    render :nothing => true unless authorized
  end

end
