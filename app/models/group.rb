class Group < ActiveRecord::Base
  Source = __FILE__
  include Extensions::ActiveRecord

  has_many :roles, :dependent => :destroy

  has_many :members, :through => :roles, :source => :login,
      :conditions => { 'roles.type' => 'Role::Belonging' }
  has_many :leaders, :through => :roles, :source => :login,
      :conditions => { 'roles.type' => 'Role::Leading' }

  validates_presence_of :name

  attr_accessor :q

  def self.search(attributes, opts = {})
    attributes ||= {}

    scope = if attributes[:q].blank? then {}
    else
      { :conditions => ['name LIKE ?', "%#{ attributes[:q] }%"] }
    end

    return with_scope(scope) { find :all, opts }, Group.new(attributes)
  end

end
