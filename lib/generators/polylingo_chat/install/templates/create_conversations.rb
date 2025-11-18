class CreatePolylingoChatConversations < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :polylingo_chat_conversations do |t|
      t.string :title
      t.boolean :private, default: true
      t.timestamps
    end
  end
end
