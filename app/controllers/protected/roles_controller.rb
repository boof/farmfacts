class Protected::RolesController < Protected::Base

  before_filter :correct_method?
  before_filter :assign_group
  before_filter :authorized?

  def belongs_to
    destroy false

    login = Login.find params[:login_id]
    role = login.memberships.new :group => @group

    role.save!

    redirect_to return_uri
  end
  def destroy(redirect = true)
    role = @group.roles.find_by_login_id params[:login_id]
    role.destroy if role
      
    redirect_to return_uri if redirect
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
    visitor.admin? or visitor.leader_of? @group
  end

end
