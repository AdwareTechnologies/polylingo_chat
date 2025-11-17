require 'rails/generators'
require 'rails/generators/migration'

module PolylingoChat
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc "Installs PolylingoChat with real-time multilingual chat"

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "create_conversations.rb", "db/migrate/create_conversations.rb"
        migration_template "create_participants.rb", "db/migrate/create_participants.rb"
        migration_template "create_messages.rb", "db/migrate/create_messages.rb"
      end

      def create_models
        template "models/conversation.rb", "app/models/conversation.rb"
        template "models/participant.rb", "app/models/participant.rb"
        template "models/message.rb", "app/models/message.rb"
      end

      def create_channels
        empty_directory "app/channels/application_cable"
        template "channels/application_cable/channel.rb", "app/channels/application_cable/channel.rb"
        template "channels/application_cable/connection.rb", "app/channels/application_cable/connection.rb"
        template "channels/polylingo_chat_channel.rb", "app/channels/polylingo_chat_channel.rb"
      end

      def create_javascript_files
        empty_directory "app/javascript/channels"
        template "javascript/chat.js", "app/javascript/chat.js"
        template "javascript/channels/consumer.js", "app/javascript/channels/consumer.js"
        template "javascript/channels/index.js", "app/javascript/channels/index.js"
      end

      def configure_cable
        if File.exist?("config/cable.yml")
          gsub_file "config/cable.yml", /^development:\s*\n\s+adapter:\s+\w+.*$/m do |match|
            "development:\n  adapter: solid_cable\n  polling_interval: 0.1.seconds\n  message_retention: 1.day"
          end
        end
      end

      def setup_solid_cable
        say "Setting up Solid Cable...", :green
        rails_command "solid_cable:install", abort_on_failure: false
      end

      def download_actioncable
        empty_directory "vendor/javascript"
        say "Downloading ActionCable ESM module...", :green
        run "curl -o vendor/javascript/@rails--actioncable.js https://ga.jspm.io/npm:@rails/actioncable@7.1.3/app/assets/javascripts/actioncable.esm.js"
      end

      def add_routes
        route 'mount ActionCable.server => "/cable"'
        route <<~RUBY
          resources :conversations do
            resources :messages, only: [:create]
          end
        RUBY
      end

      def update_importmap
        if File.exist?("config/importmap.rb")
          append_to_file "config/importmap.rb" do
            <<~RUBY

              # PolylingoChat real-time chat
              pin "@rails/actioncable", to: "@rails--actioncable.js"
              pin_all_from "app/javascript/channels", under: "channels"
              pin "chat", to: "chat.js"
            RUBY
          end
        end
      end

      def update_application_js
        if File.exist?("app/javascript/application.js")
          append_to_file "app/javascript/application.js" do
            <<~JS

              // PolylingoChat real-time chat
              import "chat"
            JS
          end
        end
      end

      def create_initializer
        template "initializer.rb", "config/initializers/polylingo_chat.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
