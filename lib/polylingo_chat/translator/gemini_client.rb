require 'faraday'
require 'json'
require 'digest'

module PolylingoChat
  module Translator
    class GeminiClient < Base
      class << self
        def detect_language(text)
          return 'unknown' if text.nil? || text.strip.empty?
          prompt = "Detect language for the following text and return the ISO 639-1 code only:\n\n#{text}"
          resp = gemini_generate(prompt, system: 'You are a language detection assistant. Return only the lowercase ISO 639-1 code.')
          code = resp.to_s.strip[0,2]&.downcase
          code || 'unknown'
        end

        def translate(text:, from: nil, to:, context: nil)
          raise PolylingoChat::Error, 'target language required' if to.nil? || to.to_s.strip.empty?
          return '' if text.nil?

          # caching
          cache_key = "polylingo_chat:#{Digest::SHA1.hexdigest([text, from, to, context].join(':'))}"
          if (cache = PolylingoChat.config.cache_store)
            cached = cache.get(cache_key) rescue StandardError; nil
            return JSON.parse(cached)['translated'] if cached
          end

          prompt = build_prompt(text: text, from: from, to: to, context: context)
          translated = gemini_generate(prompt, system: 'You are a translation assistant. Return only the translated text with no additional commentary.')

          if (cache = PolylingoChat.config.cache_store)
            begin
              cache.set(cache_key, { translated: translated }.to_json)
            rescue StandardError => e
              # ignore cache failures
            end
          end

          translated
        end

        private

        def build_prompt(text:, from:, to:, context:)
          ctx = context ? "CONTEXT:\n#{context}\n\n" : ''
          src = from ? "(source language: #{from})" : '(source language unknown)'
          "Translate the following text to #{to}. #{src}\n\n#{ctx}TEXT:\n#{text}"
        end

        def gemini_generate(prompt, system: nil)
          api_key = PolylingoChat.config.api_key
          raise PolylingoChat::Error, 'API key not configured' unless api_key

          model = PolylingoChat.config.model || 'gemini-1.5-flash'

          conn = Faraday.new(url: 'https://generativelanguage.googleapis.com', request: { timeout: PolylingoChat.config.timeout, open_timeout: 5 }) do |f|
            f.request :json
            f.adapter Faraday.default_adapter
          end

          contents = []
          contents << { role: 'user', parts: [{ text: system }] } if system
          contents << { role: 'user', parts: [{ text: prompt }] }

          body = {
            contents: contents,
            generationConfig: {
              temperature: 0.0,
              maxOutputTokens: 1024
            }
          }

          res = conn.post("/v1beta/models/#{model}:generateContent?key=#{api_key}") do |r|
            r.headers['Content-Type'] = 'application/json'
            r.body = body.to_json
          end

          if res.status >= 400
            raise PolylingoChat::Error, "Gemini API error: #{res.status} - #{res.body}"
          end

          parsed = JSON.parse(res.body)
          parsed.dig('candidates', 0, 'content', 'parts', 0, 'text') || ''
        end
      end
    end
  end
end
