module PolylingoChat
  class MessagesController < PolylingoChat::ApplicationController
    before_action :set_conversation

    # GET /polylingo_chat/conversations/:conversation_id/messages
    # Optional query params:
    #   - lang: ISO 639-1 code (e.g., 'es', 'fr', 'de') - uses cached translations
    def index
      @messages = @conversation.messages.order(created_at: :asc)

      respond_to do |format|
        format.html # renders app/views/polylingo_chat/messages/index.html.erb
        format.json do
          # Support language query parameter for API consumers (uses cached translations)
          target_language = params[:lang]
          render json: @messages.map { |m| message_json(m, target_language: target_language) }
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
        # Trigger translation and broadcasting job
        # Use perform_now in development to avoid SQLite locking issues
        if Rails.env.development?
          PolylingoChat::TranslateJob.perform_now(@message.id)
        else
          PolylingoChat::TranslateJob.perform_later(@message.id)
        end

        respond_to do |format|
          format.html { redirect_to conversation_path(@conversation), notice: 'Message sent successfully.' }
          format.json { render json: message_json(@message), status: :created }
        end
      else
        respond_to do |format|
          format.html { redirect_to conversation_path(@conversation), alert: 'Failed to send message.' }
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

    def message_json(message, target_language: nil)
      json = {
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

      # If target_language specified, include that specific cached translation
      if target_language.present?
        json[:translation] = message.translation_for(target_language)
        json[:translation_language] = target_language
      end

      # Always include all available cached translations for API consumers
      json[:available_translations] = message.translations.map do |t|
        { language: t.language, text: t.translated_text }
      end

      json
    end

  end
end
