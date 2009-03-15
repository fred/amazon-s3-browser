class CreateRecentAmis < ActiveRecord::Migration
  def self.up
    create_table :recent_amis do |t|
      t.string :ami
      t.datetime :last_used
    end
    add_index :recent_amis, :last_used
  end

  def self.down
    drop_table :recent_amis
  end
end
