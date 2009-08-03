class Role < ActiveRecord::Base

  attr_protected :type, :group_id, :login_id
  belongs_to :login
  validates_presence_of :login_id
  validates_uniqueness_of :type, :scope => [:login_id, :group_id]

end
