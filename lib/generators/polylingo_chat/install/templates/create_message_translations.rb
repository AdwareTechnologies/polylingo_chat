class CreatePolylingoChatMessageTranslations < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :polylingo_chat_message_translations do |t|
      t.references :message, null: false, foreign_key: { to_table: :polylingo_chat_messages }
      t.string :language, null: false
      t.text :translated_text, null: false

      t.timestamps
    end

    add_index :polylingo_chat_message_translations, [:message_id, :language], unique: true, name: 'idx_message_translations_on_message_and_language'
  end
end
