# Polyglot Configuration
# For more information, see: https://github.com/shoaibmalik786/polyglot

Polyglot.configure do |config|
  # ========================================
  # AI Provider Configuration (OPTIONAL)
  # ========================================

  # Translation is OPTIONAL! If you don't set an API key, Polyglot works as a
  # real-time chat engine without translation (messages sent as-is).

  # To enable translation, choose your AI provider: :openai, :anthropic, or :gemini
  config.provider = :openai

  # Set your API key (leave nil to use chat-only mode without translation)
  config.api_key = ENV['POLYGLOT_API_KEY']  # or set to nil for chat-only mode

  # Choose your model based on provider:
  # OpenAI: 'gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo'
  # Anthropic: 'claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022', 'claude-3-opus-20240229'
  # Gemini: 'gemini-1.5-flash', 'gemini-1.5-pro'
  config.model = 'gpt-4o-mini'

  # ========================================
  # Background Job Configuration
  # ========================================

  # Specify which ActiveJob adapter you're using (OPTIONAL, for documentation purposes)
  # You still need to configure ActiveJob in your Rails app as normal
  # Options: :sidekiq, :solid_queue, :delayed_job, :async, :inline, etc.
  #
  # Example ActiveJob configuration (in config/application.rb or config/environments/*.rb):
  #   config.active_job.queue_adapter = :sidekiq
  #
  # Then tell Polyglot which adapter you're using:
  config.queue_adapter = :sidekiq  # Change this to match your ActiveJob setup

  # Enable/disable async processing
  config.async = true

  # ========================================
  # Translation Configuration
  # ========================================

  # Default language for translations (ISO 639-1 code)
  config.default_language = 'en'

  # Enable caching for translations (recommended for production)
  config.cache_store = Rails.cache

  # Request timeout in seconds
  config.timeout = 15
end
