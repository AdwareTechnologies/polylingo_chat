class CreatePolyglotMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :conversation, null: false, foreign_key: true
      t.text :body
      t.string :language
      t.text :translated_body
      t.boolean :translated, default: false
      t.timestamps
    end
  end
end
