class CreateConversations < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :conversations do |t|
      t.string :title
      t.boolean :private, default: true
      t.timestamps
    end
  end
end
