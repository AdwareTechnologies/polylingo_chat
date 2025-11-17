require_relative 'translator/base'
require_relative 'translator/openai_client'
require_relative 'translator/anthropic_client'
require_relative 'translator/gemini_client'

module Polyglot
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
        case Polyglot.config.provider
        when :openai
          Polyglot::Translator::OpenAIClient
        when :anthropic
          Polyglot::Translator::AnthropicClient
        when :gemini
          Polyglot::Translator::GeminiClient
        else
          Polyglot::Translator::OpenAIClient
        end
      end

      def reset_provider!
        @provider_client = nil
        configure_provider
      end
    end
  end
end
