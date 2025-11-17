class CreatePolyglotConversations < ActiveRecord::Migration[6.0]
  def change
    create_table :conversations do |t|
      t.string :title
      t.boolean :private, default: true
      t.timestamps
    end
  end
end
