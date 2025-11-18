module PolylingoChat
  class TranslateJob < ::ApplicationJob
    queue_as :polylingo_chat_translations

    def perform(message_id)
      # Find message using namespaced model
      message = PolylingoChat::Message.find_by(id: message_id)
      return unless message

      conversation = message.conversation
      return unless conversation

      # Get all participants except the sender (works with polymorphic associations)
      recipient_participants = conversation.participants.where.not(
        participantable_type: message.sender_type,
        participantable_id: message.sender_id
      )
      recipients = recipient_participants.map(&:participantable)

      # Check if translation is enabled (API key present)
      translation_enabled = PolylingoChat.config.api_key.present?

      # Detect and store the source language
      if translation_enabled
        source_lang = PolylingoChat::Translator.detect_language(message.body)
        message.update_column(:language, source_lang)
      end

      # Store default translation (to default_language) for API consumers
      if translation_enabled
        default_lang = PolylingoChat.config.default_language
        unless source_lang == default_lang
          context = conversation.messages.order(created_at: :asc).last(20).pluck(:body).join("") rescue nil
          default_translation = PolylingoChat::Translator.translate(
            text: message.body,
            from: source_lang,
            to: default_lang,
            context: context
          )
          default_translation = default_translation.value if default_translation.respond_to?(:value)
          message.update_column(:translated_body, default_translation)
        end
      end

      recipients.each do |recipient|
        target_lang = recipient.preferred_language || PolylingoChat.config.default_language

        if translation_enabled
          # Skip if already in target language
          unless source_lang == target_lang
            # Check if translation already exists
            existing_translation = message.translations.find_by(language: target_lang)

            unless existing_translation
              # Translation enabled - translate message for this specific recipient
              context = conversation.messages.order(created_at: :asc).last(20).pluck(:body).join("") rescue nil

              translated = PolylingoChat::Translator.translate(text: message.body, from: source_lang, to: target_lang, context: context)
              # If translator returns a Future-like, wait
              translated = translated.value if translated.respond_to?(:value)

              # Save translation to database
              message.translations.create!(language: target_lang, translated_text: translated.to_s)
            else
              translated = existing_translation.translated_text
            end
          else
            translated = message.body
          end
        else
          # No API key - just use original message (chat-only mode)
          translated = message.body
        end

        # Broadcast to recipient using ActionCable (skip if API-only)
        begin
          if defined?(ActionCable)
            # Broadcast to user-specific channel
            ActionCable.server.broadcast("polylingo_chat_recipient_#{recipient.id}", {
              message: translated,
              original: message.body,
              message_id: message.id,
              sender_id: message.sender_id,
              sender_name: message.sender_name,
              translated: translation_enabled
            })

            # Also broadcast to conversation channel for demo/group chat
            ActionCable.server.broadcast("conversation_#{conversation.id}", {
              message: translated,
              original: message.body,
              message_id: message.id,
              sender_id: message.sender_id,
              sender_name: message.sender_name,
              translated: translation_enabled,
              recipient_id: recipient.id
            })
          end
        rescue StandardError => e
          Rails.logger.error("PolylingoChat: Broadcast failed - #{e.message}")
        end
      end

      message.update_column(:translated, translation_enabled)
    rescue StandardError => e
      Rails.logger.error("PolylingoChat: Failed to process translation - #{e.message}")
    end
  end
end
