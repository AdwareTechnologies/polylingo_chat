module PolylingoChat
  class MessagesController < PolylingoChat::ApplicationController
    before_action :set_conversation
    before_action :set_message, only: [:mark_as_read]

    # GET /polylingo_chat/conversations/:conversation_id/messages
    # Optional query params:
    #   - lang: ISO 639-1 code (e.g., 'es', 'fr', 'de') - uses cached translations
    def index
      @messages = @conversation.messages.order(created_at: :asc)
      # Mark messages as read by current user
      mark_messages_as_read(@messages) if current_user

      respond_to do |format|
        format.html # renders app/views/polylingo_chat/messages/index.html.erb
        format.json do
          # Support language query parameter for API consumers (uses cached translations)
          target_language = params[:lang]
          render json: @messages.map { |m| message_json(m, target_language: target_language) }
        end
      end
    end

    # POST /polylingo_chat/conversations/:conversation_id/messages/:id/mark_as_read
    # API endpoint to explicitly mark a message as read
    def mark_as_read
      unless current_user
        render json: { error: 'Authentication required' }, status: :unauthorized
        return
      end

      # Don't allow marking own messages as read
      if @message.sender == current_user
        render json: { error: 'Cannot mark your own message as read' }, status: :unprocessable_entity
        return
      end

      receipt = @message.mark_as_read_by(current_user)

      render json: {
        message: 'Message marked as read',
        read_at: receipt.read_at,
        message_id: @message.id
      }, status: :ok
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

    def set_message
      @message = @conversation.messages.find(params[:id])
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

      # Add read status for current user
      if current_user
        json[:read] = message.read_by?(current_user)
        json[:read_at] = message.read_at_by(current_user)
      end

      json
    end

    def mark_messages_as_read(messages)
      return unless current_user

      messages.each do |message|
        # Don't mark own messages as read
        next if message.sender == current_user
        # Mark as read if not already read
        message.mark_as_read_by(current_user) unless message.read_by?(current_user)
      end
    end

  end
end
