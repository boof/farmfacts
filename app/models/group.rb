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

  def self.search(attributes)
    attributes ||= {}

    groups = if attributes[:q].blank?
      find :all
    else
      term = "%#{ attributes[:q] }%"
      find :all, :conditions => ['name LIKE ?', term]
    end

    return groups, Group.new(attributes)
  end

end
