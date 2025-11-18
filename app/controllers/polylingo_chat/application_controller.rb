module PolylingoChat
  class ApplicationController < ::ApplicationController
    # Disable CSRF protection for JSON API requests (API-only mode)
    protect_from_forgery with: :null_session, if: -> { request.format.json? }

    # Allow host app to override current_user detection
    def current_user
      # Try to use the main application's current_user method
      super if defined?(super)
    rescue NoMethodError
      # If no current_user method exists in main app, return nil
      nil
    end

    helper_method :current_user
  end
end
