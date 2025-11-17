require 'rails/railtie'

module PolylingoChat
  class Railtie < Rails::Railtie
    # PolylingoChat Railtie - currently just for initialization hooks
    # The queue_adapter config is informational - users configure ActiveJob themselves

    initializer 'polylingo_chat.log_configuration', after: :load_config_initializers do
      if PolylingoChat.config.queue_adapter
        Rails.logger.info "PolylingoChat: Using #{PolylingoChat.config.queue_adapter} for background jobs"
      end
    end
  end
end
