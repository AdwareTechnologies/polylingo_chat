require 'rails/railtie'

module Polyglot
  class Railtie < Rails::Railtie
    # Polyglot Railtie - currently just for initialization hooks
    # The queue_adapter config is informational - users configure ActiveJob themselves

    initializer 'polyglot.log_configuration', after: :load_config_initializers do
      if Polyglot.config.queue_adapter
        Rails.logger.info "Polyglot: Using #{Polyglot.config.queue_adapter} for background jobs"
      end
    end
  end
end
