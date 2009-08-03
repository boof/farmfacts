class Group < ActiveRecord::Base

  has_many :roles

  has_many :members, :through => :roles, :source => :login,
      :conditions => { 'roles.type' => 'Role::Belonging' }
  has_many :leaders, :through => :roles, :source => :login,
      :conditions => { 'roles.type' => 'Role::Leading' }

end
