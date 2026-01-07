class CreatePolylingoChatMessageReadReceipts < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :polylingo_chat_message_read_receipts do |t|
      t.references :message, null: false, foreign_key: { to_table: :polylingo_chat_messages }
      t.references :reader, polymorphic: true, null: false
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :polylingo_chat_message_read_receipts, [:message_id, :reader_type, :reader_id], unique: true, name: 'idx_read_receipts_unique'
    add_index :polylingo_chat_message_read_receipts, [:reader_type, :reader_id]
  end
end
