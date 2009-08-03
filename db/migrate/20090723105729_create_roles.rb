class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.references :login, :null => false
      t.references :group
      t.string :type
      t.timestamps
    end
    add_index :roles, :login_id
    add_index :roles, :group_id
    add_index :roles, [ :login_id, :group_id, :type ], :unique => true
  end

  def self.down
    drop_table :roles
  end
end
