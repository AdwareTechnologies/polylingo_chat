require 'spec_helper'

RSpec.describe PolylingoChat::Config do
  describe '#initialize' do
    subject(:config) { described_class.new }

    it 'sets default provider to openai' do
      expect(config.provider).to eq(:openai)
    end

    it 'sets default model to gpt-4o-mini' do
      expect(config.model).to eq('gpt-4o-mini')
    end

    it 'sets default language to en' do
      expect(config.default_language).to eq('en')
    end

    it 'sets async to true by default' do
      expect(config.async).to be true
    end

    it 'sets default timeout to 15' do
      expect(config.timeout).to eq(15)
    end

    it 'sets queue_adapter to nil by default' do
      expect(config.queue_adapter).to be_nil
    end
  end

  describe '.configure' do
    it 'allows configuration via block' do
      PolylingoChat.configure do |config|
        config.provider = :anthropic
        config.model = 'claude-3-opus'
        config.default_language = 'es'
        config.queue_adapter = :sidekiq
      end

      expect(PolylingoChat.config.provider).to eq(:anthropic)
      expect(PolylingoChat.config.model).to eq('claude-3-opus')
      expect(PolylingoChat.config.default_language).to eq('es')
      expect(PolylingoChat.config.queue_adapter).to eq(:sidekiq)
    end

    it 'allows setting queue_adapter to different values' do
      PolylingoChat.configure do |config|
        config.queue_adapter = :solid_queue
      end

      expect(PolylingoChat.config.queue_adapter).to eq(:solid_queue)
    end
  end
end
