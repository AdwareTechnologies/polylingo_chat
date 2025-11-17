require 'rails/generators'
module PolylingoChat
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        template 'polylingo_chat.rb', 'config/initializers/polylingo_chat.rb'
      end

      def copy_channel
        template 'polylingo_chat_chat_channel.rb', 'app/channels/polylingo_chat_chat_channel.rb'
      end

      def copy_js_example
        template 'chat_channel_example.js', 'app/javascript/channels/polylingo_chat_chat_channel.js'
      end

      def copy_models
        template 'models/conversation.rb', 'app/models/conversation.rb'
        template 'models/participant.rb',  'app/models/participant.rb'
        template 'models/message.rb',      'app/models/message.rb'
      end

      def copy_migrations
        migration_template 'create_polylingo_chat_conversations.rb', 'db/migrate/create_polylingo_chat_conversations.rb'
        migration_template 'create_polylingo_chat_participants.rb',  'db/migrate/create_polylingo_chat_participants.rb'
        migration_template 'create_polylingo_chat_messages.rb',      'db/migrate/create_polylingo_chat_messages.rb'
      rescue => e
        say_status('warning', 'Skipping migrations: ensure you add your own Message/Conversation models or run generator again with --migrate', :yellow)
      end

      def show_readme
        readme 'INSTALL_README.md' if behavior == :invoke
      end
    end
  end
end
