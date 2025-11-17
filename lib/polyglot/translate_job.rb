module Polyglot
  class TranslateJob < ActiveJob::Base
    queue_as :polyglot_translations

    def perform(message_id)
      # Host app must implement Message model with associations matching spec
      message = ::Message.find_by(id: message_id)
      return unless message

      conversation = message.conversation
      return unless conversation

      recipients = conversation.users.where.not(id: message.sender_id)

      # Check if translation is enabled (API key present)
      translation_enabled = Polyglot.config.api_key.present?

      recipients.each do |recipient|
        if translation_enabled
          # Translation enabled - translate message
          target_lang = recipient.preferred_language || Polyglot.config.default_language
          source_lang = Polyglot::Translator.detect_language(message.body)
          context = conversation.messages.order(created_at: :asc).last(20).pluck(:body).join("") rescue nil

          translated = Polyglot::Translator.translate(text: message.body, from: source_lang, to: target_lang, context: context)
          # If translator returns a Future-like, wait
          translated = translated.value if translated.respond_to?(:value)
        else
          # No API key - just use original message (chat-only mode)
          translated = message.body
        end

        # Broadcast to recipient using ActionCable
        begin
          # Broadcast to user-specific channel
          ActionCable.server.broadcast("polyglot_recipient_#{recipient.id}", {
            message: translated,
            original: message.body,
            message_id: message.id,
            sender_id: message.sender_id,
            sender_name: message.sender.name,
            translated: translation_enabled
          })

          # Also broadcast to conversation channel for demo/group chat
          ActionCable.server.broadcast("conversation_#{conversation.id}", {
            message: translated,
            original: message.body,
            message_id: message.id,
            sender_id: message.sender_id,
            sender_name: message.sender.name,
            translated: translation_enabled,
            recipient_id: recipient.id
          })
        rescue => e
          # ignore broadcast errors
        end
      end

      message.update(translated: translation_enabled) rescue nil
    end
  end
end
