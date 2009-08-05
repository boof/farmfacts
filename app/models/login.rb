class Login < ActiveRecord::Base
  CHARS = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a

  default_scope :order => 'last_name, first_name'

  has_many :roles
  has_many :leaderships, :class_name => 'LeadingRole'
  has_many :memberships, :class_name => 'BelongingRole'
  has_many :groups, :through => :memberships

  def save_as_administrator
    save and roles << AdministeringRole.new
  end
  alias_method :save_as_admin, :save_as_administrator

  def save_as_leader(group)
    save and roles << LeadingRole.new(:group => group)
  end

  def leads?(group)
    leaderships.exists? :group_id => group.try(:id)
  end
  def administrator?
    roles.exists? :type => 'AdministeringRole'
  end
  alias_method :admin?, :administrator?

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

end