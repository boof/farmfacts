class BelongingRole < Role
  Source = __FILE__
  include Extensions::ActiveRecord

  validates_presence_of :group_id

  def leading?
    false
  end

end
