require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler/setup'

# Load only the necessary parts for testing without Rails Engine
require 'active_support'
require 'active_support/core_ext'

# Load polylingo_chat components individually to avoid Rails engine loading issues
require_relative '../lib/polylingo_chat/version'
require_relative '../lib/polylingo_chat/config'
require_relative '../lib/polylingo_chat/translator/base'
require_relative '../lib/polylingo_chat/translator/openai_client'
require_relative '../lib/polylingo_chat/translator/anthropic_client'
require_relative '../lib/polylingo_chat/translator/gemini_client'

# Initialize PolylingoChat module if not already defined
module PolylingoChat
  class Error < StandardError; end

  def self.configure
    @config ||= Config.new
    yield @config if block_given?
    @config
  end

  def self.config
    @config ||= Config.new
  end
end

# Load translator module
module PolylingoChat
  module Translator
    class << self
      def detect_language(text)
        provider_client.detect_language(text)
      end

      def translate(text:, from: nil, to:, context: nil)
        provider_client.translate(text: text, from: from, to: to, context: context)
      end

      def provider_client
        @provider_client ||= configure_provider
      end

      def configure_provider
        case PolylingoChat.config.provider
        when :openai
          PolylingoChat::Translator::OpenAIClient
        when :anthropic
          PolylingoChat::Translator::AnthropicClient
        when :gemini
          PolylingoChat::Translator::GeminiClient
        else
          PolylingoChat::Translator::OpenAIClient
        end
      end

      def reset_provider!
        @provider_client = nil
        configure_provider
      end
    end
  end
end

require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<API_KEY>') { ENV['POLYGLOT_API_KEY'] }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  # Reset provider before each test
  config.before(:each) do
    PolylingoChat.instance_variable_set(:@config, nil)
    PolylingoChat::Translator.reset_provider!
  end
end
