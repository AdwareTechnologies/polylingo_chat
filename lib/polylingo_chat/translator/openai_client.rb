require 'faraday'
require 'json'
require 'digest'

module PolylingoChat
  module Translator
    class OpenAIClient < Base
      class << self
        def detect_language(text)
          return 'unknown' if text.nil? || text.strip.empty?
          prompt = "Detect language for the following text and return the ISO 639-1 code only:

#{text}"
          resp = openai_chat(prompt, system: 'You are a language detection assistant. Return only the lowercase ISO 639-1 code.')
          code = resp.to_s.strip[0,2]&.downcase
          code || 'unknown'
        end

        def translate(text:, from: nil, to:, context: nil)
          raise PolylingoChat::Error, 'target language required' if to.nil? || to.to_s.strip.empty?
          return '' if text.nil?

          # caching
          cache_key = "polylingo_chat:#{Digest::SHA1.hexdigest([text, from, to, context].join(':'))}"
          if (cache = PolylingoChat.config.cache_store)
            cached = cache.get(cache_key) rescue nil
            return JSON.parse(cached)['translated'] if cached
          end

          prompt = build_prompt(text: text, from: from, to: to, context: context)
          translated = openai_chat(prompt, system: 'You are a translation assistant. Return only the translated text with no additional commentary.')

          if (cache = PolylingoChat.config.cache_store)
            begin
              cache.set(cache_key, { translated: translated }.to_json)
            rescue => e
              # ignore cache failures
            end
          end

          translated
        end

        private

        def build_prompt(text:, from:, to:, context:)
          ctx = context ? "CONTEXT:
#{context}

" : ''
          src = from ? "(source language: #{from})" : '(source language unknown)'
          "Translate the following text to #{to}. #{src}

#{ctx}TEXT:
#{text}"
        end

        def openai_chat(prompt, system: nil)
          api_key = PolylingoChat.config.api_key
          raise PolylingoChat::Error, 'API key not configured' unless api_key

          conn = Faraday.new(url: 'https://api.openai.com', request: { timeout: PolylingoChat.config.timeout, open_timeout: 5 }) do |f|
            f.request :json
            f.adapter Faraday.default_adapter
          end

          body = {
            model: PolylingoChat.config.model,
            messages: [
              { role: 'system', content: system || 'You are a helpful assistant.' },
              { role: 'user', content: prompt }
            ],
            temperature: 0.0
          }

          res = conn.post('/v1/chat/completions') do |r|
            r.headers['Authorization'] = "Bearer #{api_key}"
            r.headers['Content-Type'] = 'application/json'
            r.body = body.to_json
          end

          if res.status >= 400
            raise PolylingoChat::Error, "OpenAI API error: #{res.status} - #{res.body}"
          end

          parsed = JSON.parse(res.body)
          parsed.dig('choices', 0, 'message', 'content') || ''
        end
      end
    end
  end
end
