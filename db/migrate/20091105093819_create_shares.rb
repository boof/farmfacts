class CreateShares < ActiveRecord::Migration
  def self.up
    create_table :shares do |shares|
      shares.references :login
      shares.references :page
      shares.timestamps
    end
    add_index :shares, [:login_id, :page_id], :unique => true
    add_index :shares, [:page_id, :updated_at]
  end

  def self.down
    drop_table :shares
  end
end
