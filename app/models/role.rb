class Role < ActiveRecord::Base
  Source = __FILE__
  include Extensions::ActiveRecord

  attr_protected :type, :group_id, :login_id
  belongs_to :login
  belongs_to :group
  validates_presence_of :login_id
  validates_uniqueness_of :login_id, :scope => :group_id

  def self.translated_name
    I18n.translate("activerecord.models.#{ name.underscore }")
  end
  def name
    self.class.translated_name
  end

end
