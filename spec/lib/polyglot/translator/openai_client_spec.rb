require 'spec_helper'

RSpec.describe Polyglot::Translator::OpenAIClient do
  before do
    Polyglot.configure do |config|
      config.provider = :openai
      config.api_key = 'test_api_key'
      config.model = 'gpt-4o-mini'
    end
  end

  describe '.detect_language' do
    it 'returns unknown for nil text' do
      expect(described_class.detect_language(nil)).to eq('unknown')
    end

    it 'returns unknown for empty text' do
      expect(described_class.detect_language('')).to eq('unknown')
    end

    context 'with valid text', :vcr do
      it 'detects the language' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(
            status: 200,
            body: {
              choices: [{ message: { content: 'en' } }]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = described_class.detect_language('Hello, how are you?')
        expect(result).to eq('en')
      end
    end
  end

  describe '.translate' do
    it 'raises error when target language is missing' do
      expect {
        described_class.translate(text: 'Hello', from: 'en', to: nil)
      }.to raise_error(Polyglot::Error, 'target language required')
    end

    it 'returns empty string for nil text' do
      expect(described_class.translate(text: nil, from: 'en', to: 'es')).to eq('')
    end

    context 'with valid parameters', :vcr do
      it 'translates text successfully' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(
            status: 200,
            body: {
              choices: [{ message: { content: 'Hola' } }]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = described_class.translate(text: 'Hello', from: 'en', to: 'es')
        expect(result).to eq('Hola')
      end
    end

    context 'when API returns error' do
      it 'raises Polyglot::Error' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 500, body: 'Internal Server Error')

        expect {
          described_class.translate(text: 'Hello', from: 'en', to: 'es')
        }.to raise_error(Polyglot::Error, /OpenAI API error/)
      end
    end
  end
end
