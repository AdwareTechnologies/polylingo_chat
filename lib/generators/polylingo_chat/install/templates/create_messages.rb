class CreatePolylingoChatMessages < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :polylingo_chat_messages do |t|
      # Polymorphic sender - supports User, Vendor, Customer, etc.
      t.references :sender, polymorphic: true, null: false
      t.references :conversation, null: false, foreign_key: { to_table: :polylingo_chat_conversations }
      t.text :body
      t.string :language
      t.text :translated_body
      t.boolean :translated, default: false
      t.timestamps
    end

    add_index :polylingo_chat_messages, [:sender_type, :sender_id]
    add_index :polylingo_chat_messages, [:conversation_id, :created_at]
  end
end
