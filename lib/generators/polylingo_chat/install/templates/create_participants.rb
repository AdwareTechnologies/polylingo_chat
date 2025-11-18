class CreatePolylingoChatParticipants < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :polylingo_chat_participants do |t|
      # Polymorphic association - supports User, Vendor, Customer, etc.
      t.references :participantable, polymorphic: true, null: false
      t.references :conversation, null: false, foreign_key: { to_table: :polylingo_chat_conversations }
      t.string :role
      t.timestamps
    end

    add_index :polylingo_chat_participants, [:participantable_type, :participantable_id, :conversation_id],
              unique: true,
              name: 'index_polylingo_participants_on_participantable_conversation'
  end
end
