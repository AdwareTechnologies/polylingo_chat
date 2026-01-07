require 'rails/generators'
require 'rails/generators/migration'

module PolylingoChat
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      class_option :api_only, type: :boolean, default: nil,
                   desc: "Install for API-only Rails app (skip ActionCable/frontend)"

      desc "Installs PolylingoChat with real-time multilingual chat"

      def initialize(*args)
        super
        @api_only = detect_api_only_mode
      end

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "create_conversations.rb", "db/migrate/create_polylingo_chat_conversations.rb"
        migration_template "create_participants.rb", "db/migrate/create_polylingo_chat_participants.rb"
        migration_template "create_messages.rb", "db/migrate/create_polylingo_chat_messages.rb"
        migration_template "create_message_translations.rb", "db/migrate/create_polylingo_chat_message_translations.rb"
        migration_template "create_message_read_receipts.rb", "db/migrate/create_polylingo_chat_message_read_receipts.rb"
      end

      def create_channels
        return if @api_only
        empty_directory "app/channels/application_cable"
        template "channels/application_cable/channel.rb", "app/channels/application_cable/channel.rb"
        template "channels/application_cable/connection.rb", "app/channels/application_cable/connection.rb"
        template "channels/polylingo_chat_channel.rb", "app/channels/polylingo_chat_channel.rb"
      end

      def create_javascript_files
        return if @api_only
        empty_directory "app/javascript/channels"
        template "javascript/chat.js", "app/javascript/chat.js"
        template "javascript/channels/consumer.js", "app/javascript/channels/consumer.js"
        template "javascript/channels/index.js", "app/javascript/channels/index.js"
      end

      def configure_cable
        return if @api_only
        if File.exist?("config/cable.yml")
          gsub_file "config/cable.yml", /^development:\s*\n\s+adapter:\s+\w+.*$/m do |match|
            "development:\n  adapter: solid_cable\n  polling_interval: 0.1.seconds\n  message_retention: 1.day"
          end
        end
      end

      def setup_solid_cable
        return if @api_only
        say "Setting up Solid Cable...", :green
        rails_command "solid_cable:install", abort_on_failure: false
      end

      def download_actioncable
        return if @api_only
        empty_directory "vendor/javascript"
        say "Downloading ActionCable ESM module...", :green
        run "curl -o vendor/javascript/@rails--actioncable.js https://ga.jspm.io/npm:@rails/actioncable@7.1.3/app/assets/javascripts/actioncable.esm.js"
      end

      def add_routes
        unless @api_only
          route 'mount ActionCable.server => "/cable"'
        end

        route 'mount PolylingoChat::Engine => "/polylingo_chat"'
      end

      def update_importmap
        return if @api_only
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
        return if @api_only
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

      private

      def detect_api_only_mode
        # Use explicit option if provided
        return options[:api_only] unless options[:api_only].nil?

        # Auto-detect: Check if this is an API-only Rails app
        # API-only apps typically don't have ActionView or have it explicitly disabled
        api_only = !defined?(ActionView::Base) ||
                   (defined?(Rails.application) && Rails.application.config.respond_to?(:api_only) && Rails.application.config.api_only)

        if api_only
          say "Detected API-only Rails application. Skipping ActionCable/frontend setup.", :yellow
        else
          say "Installing with full-stack support (ActionCable + frontend).", :green
        end

        api_only
      end
    end
  end
end
