class LeadingRole < BelongingRole
  Source = __FILE__
  include Extensions::ActiveRecord

  def leading?
    true
  end

end
