class Login < ActiveRecord::Base
  Source = __FILE__
  include Extensions::ActiveRecord

  CHARS = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a

  default_scope :order => 'last_name, first_name'

  attr_accessor :q

  def self.search(attributes)
    attributes ||= {}

    logins = if attributes[:q].blank?
      find :all, :include => {:roles => :group}
    else
      term = "#{ attributes[:q] }%"
      find :all, :include => {:roles => :group},
        :conditions => ['first_name LIKE ? OR last_name LIKE ? OR username LIKE ?', term, term, term]
    end

    return logins, Login.new(attributes)
  end

  # TODO: implement rbac
  has_many :roles, :dependent => :destroy do
    def administrator?
      if loaded?
        target.any? { |r| r.type == 'AdministeringRole' }
      else
        exists? :type => 'AdministeringRole'
      end
    end
    def leader_of?(group)
      if loaded?
        target.any? { |r| r.type == 'LeadingRole' and r.group_id == group.try(:id) }
      else
        exists? :type => 'LeadingRole', :group_id => group.try(:id)
      end
    end
    def member_of?(group)
      if loaded?
        target.any? { |r| r.type == 'BelongingRole' and r.group_id == group.try(:id) }
      else
        exists? :type => 'BelongingRole', :group_id => group.try(:id)
      end
    end
  end
  has_many :leaderships, :class_name => 'LeadingRole'
  has_many :memberships, :class_name => 'BelongingRole'
  has_many :groups, :through => :memberships

  def become
    @become ||= ActiveSupport::StringInquirer.new
  end
  def become=(rolename)
    @become = ActiveSupport::StringInquirer.new rolename
  end

  def is?(role)
    member_of? groups.find_by_name("#{ role }".pluralize)
  end

  def save_as_leader(group)
    save and roles << LeadingRole.new(:group => group)
  end

  delegate :administrator?, :leader_of?, :member_of?, :to => :roles
  alias_method :admin?, :administrator?
  alias_method :leads?, :leader_of?

  def self.generate_hash(*credentials)
    Digest::MD5.hexdigest credentials * '+'
  end

  def has_password?(password)
    password_hash == self.class.generate_hash(password, password_salt)
  end

  def self.authenticate(params)
    instance = case params
        when Numeric, String; find :first, :conditions => { :id => params }
        when Hash; username, password = params[:username], params[:password]
          unless username.blank? or password.blank?
            login = find_by_username username, :include => :roles
            login if login and login.has_password? password
          end
        else
          Login.new
        end

    instance or failed params
  end

  def self.failed(params)
    params = (Hash === params) ? params : {}
    instance = new params
    instance.errors.add_to_base I18n.translate('errors.models.login.failed')

    instance
  end

  def first?
    !self.class.exists?
  end
  def authenticated?
    !new_record?
  end

  def self.generate_password(length = 8)
    Array.new(length) { CHARS[ rand(CHARS.size) ] }.to_s
  end
  def self.generate_salt
    Digest::MD5.hexdigest(rand.to_s)[0, 10]
  end

  def name
    "#{ first_name } #{ last_name }"
  end

  validates_presence_of :username, :first_name, :last_name, :email
  validates_uniqueness_of :username, :email

  attr_accessor :password
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password

  def confirm_password
    @password_confirmation = @password; nil
  end

  def update_password_credentials
    unless @password.blank?
      self.password_salt = self.class.generate_salt
      self.password_hash = self.class.generate_hash @password, password_salt
    end
  end
  before_save :update_password_credentials
  protected :update_password_credentials

  def clear_password
    @password = @password_confirmation = nil
  end
  after_save :clear_password
  protected :clear_password

  def attribute_for_inspect(name)
    super if name !~ /password/
  end
  protected :attribute_for_inspect

  def set_role
    if become.administrator?
      roles << AdministeringRole.new unless administrator?
    else
      roles.find_all_by_type('AdministeringRole').each { |role| role.destroy }
    end
  end
  after_save :set_role
  protected :set_role

end
