class CreateLogins < ActiveRecord::Migration

  def self.up
    create_table :logins do |t|
      t.string :username, :null => false
      t.string :email, :null => false
      t.string :first_name
      t.string :last_name
      t.string :password_salt, :limit => 10, :null => false
      t.string :password_hash, :limit => 32, :null => false
      t.timestamps
    end
    add_index :logins, :username, :unique => true
    add_index :logins, :email, :unique => true
  end

  def self.down
    drop_table :logins
  end

end
