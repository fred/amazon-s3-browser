class CreateCommands < ActiveRecord::Migration
  def self.up
    create_table :commands do |t|
     t.string :command, :limit => 1024
     t.string :output , :limit => 16 * 1024 * 1024
     t.string :error, :limit => 16 * 1024 * 1024
     t.integer :exit_code
     t.string :instance_id
     t.string :ami
      t.timestamps
    end
  end

  def self.down
    drop_table :commands
  end
end
