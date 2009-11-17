class Share < ActiveRecord::Base

  default_scope :order => 'updated_at DESC'
  named_scope :by_author, proc { |login|
    {:conditions => {:login_id => login.id}}
  }

  belongs_to :login
  belongs_to :page

end
