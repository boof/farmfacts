class BelongingRole < Role

  belongs_to :group
  validates_presence_of :group_id

  def leading?
    false
  end

end
