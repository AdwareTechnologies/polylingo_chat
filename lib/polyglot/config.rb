module Polyglot
  class Config
    attr_accessor :provider, :api_key, :model, :default_language, :cache_store, :async, :timeout, :queue_adapter

    def initialize
      @provider = :openai
      @api_key = ENV['POLYGLOT_API_KEY']
      @model = 'gpt-4o-mini'
      @default_language = 'en'
      @cache_store = nil
      @async = true
      @timeout = 15
      @queue_adapter = nil # Optional: Specify which ActiveJob adapter you're using
    end
  end

  def self.configure
    @config ||= Config.new
    yield @config if block_given?
    @config
  end

  def self.config
    @config ||= Config.new
  end
end
