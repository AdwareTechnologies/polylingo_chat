Polyglot.configure do |config|
  # API key for AI translation service
  # Leave nil to use chat-only mode (no translation)
  config.api_key = nil

  # AI provider: :openai, :anthropic, or :gemini
  config.provider = :anthropic

  # Model to use for translation
  # OpenAI: 'gpt-4-turbo' or 'gpt-3.5-turbo'
  # Anthropic: 'claude-3-5-sonnet-20241022' or 'claude-3-haiku-20240307'
  # Gemini: 'gemini-1.5-pro' or 'gemini-1.5-flash'
  config.model = 'claude-3-5-sonnet-20241022'

  # Default language for users without a preferred language
  config.default_language = 'en'

  # Enable async job processing (requires ActiveJob)
  config.async = true

  # Queue adapter (e.g., :solid_queue, :sidekiq, :async)
  # Set to match your app's ActiveJob queue adapter
  # config.queue_adapter = :solid_queue
end
