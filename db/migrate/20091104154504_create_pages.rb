class CreatePages < ActiveRecord::Migration
  def self.up
    create_table(:pages) do |pages|
      pages.string :path
      pages.string :locale
      pages.text :outer_html
      pages.string :published_commit
      pages.timestamps
    end
    add_index :pages, [:path, :locale], :unique => true
  end

  def self.down
    drop_table(:pages)
  end
end
