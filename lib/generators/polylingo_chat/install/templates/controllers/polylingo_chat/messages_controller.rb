module PolylingoChat
  class MessagesController < ApplicationController
    before_action :set_conversation

    # GET /polylingo_chat/conversations/:conversation_id/messages
    # Optional query params:
    #   - target_language: ISO 639-1 code (e.g., 'es', 'fr', 'de')
    #   - translate: 'true' to enable on-the-fly translation
    def index
      @messages = @conversation.messages.order(created_at: :asc)

      respond_to do |format|
        format.html # renders app/views/polylingo_chat/messages/index.html.erb
        format.json do
          # Check if on-the-fly translation is requested
          if params[:translate] == 'true' && params[:target_language].present?
            render json: @messages.map { |m| translate_message_json(m, params[:target_language]) }
          else
            render json: @messages.map { |m| message_json(m) }
          end
        end
      end
    end

    # POST /polylingo_chat/conversations/:conversation_id/messages
    def create
      @message = @conversation.messages.new(message_params)

      # Set sender from params (polymorphic)
      if params[:sender_type] && params[:sender_id]
        sender_klass = params[:sender_type].constantize
        @message.sender = sender_klass.find(params[:sender_id])
      end

      if @message.save
        respond_to do |format|
          format.html { redirect_to polylingo_chat_conversation_path(@conversation), notice: 'Message sent successfully.' }
          format.json { render json: message_json(@message), status: :created }
        end
      else
        respond_to do |format|
          format.html { redirect_to polylingo_chat_conversation_path(@conversation), alert: 'Failed to send message.' }
          format.json { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_conversation
      @conversation = Conversation.find(params[:conversation_id])
    end

    def message_params
      params.require(:message).permit(:body, :language)
    end

    def message_json(message)
      {
        id: message.id,
        body: message.body,
        language: message.language,
        translated_body: message.translated_body,
        translated: message.translated,
        sender_type: message.sender_type,
        sender_id: message.sender_id,
        sender_name: message.sender_name,
        conversation_id: message.conversation_id,
        created_at: message.created_at,
        updated_at: message.updated_at
      }
    end

    def translate_message_json(message, target_language)
      # Check if translation is enabled
      unless PolylingoChat.config.api_key.present?
        return message_json(message)
      end

      # If message is already in target language, return as is
      if message.language == target_language
        return message_json(message).merge(
          translated_body: message.body,
          target_language: target_language
        )
      end

      # If we have a stored translation in the target language (for default language)
      if target_language == PolylingoChat.config.default_language && message.translated_body.present?
        return message_json(message).merge(target_language: target_language)
      end

      # Translate on-the-fly
      begin
        translated = PolylingoChat::Translator.translate(
          text: message.body,
          from: message.language || 'auto',
          to: target_language,
          context: nil
        )
        translated = translated.value if translated.respond_to?(:value)

        message_json(message).merge(
          translated_body: translated,
          target_language: target_language
        )
      rescue StandardError => e
        Rails.logger.error("PolylingoChat: Translation failed - #{e.message}")
        message_json(message).merge(target_language: target_language)
      end
    end
  end
end
