require 'rails/generators'
require 'rails/generators/migration'

module PolylingoChat
  module Generators
    class ReadReceiptsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../install/templates', __dir__)

      desc "Adds message read receipts migration to existing PolylingoChat installation"

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migration
        migration_template "create_message_read_receipts.rb",
                          "db/migrate/create_polylingo_chat_message_read_receipts.rb"
      end

      def show_instructions
        say "\n" + "=" * 80, :green
        say "Read receipts migration has been created!", :green
        say "=" * 80, :green
        say "\nNext steps:", :yellow
        say "  1. Run: rails db:migrate"
        say "  2. Messages will now automatically track read/unread status per participant"
        say "\nNew features available:", :cyan
        say "  - Message model:"
        say "    • message.mark_as_read_by(user)"
        say "    • message.read_by?(user)"
        say "    • message.unread_by?(user)"
        say "    • message.read_at_by(user)"
        say "    • Message.unread_by(user)"
        say "    • Message.read_by(user)"
        say "\n  - Conversation model:"
        say "    • conversation.unread_messages_count_for(user)"
        say "    • conversation.has_unread_messages_for?(user)"
        say "\n  - Views automatically show:"
        say "    • Read receipts (✓✓) on sent messages"
        say "    • Unread message counts on conversation list"
        say "\n"
      end
    end
  end
end
