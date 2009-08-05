class BelongingRole < Role

  validates_presence_of :group_id

  def leading?
    false
  end

end
