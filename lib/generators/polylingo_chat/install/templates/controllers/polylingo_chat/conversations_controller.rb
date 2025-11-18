module PolylingoChat
  class ConversationsController < ApplicationController
    before_action :set_conversation, only: [:show, :update, :destroy]

    # GET /polylingo_chat/conversations
    def index
      @conversations = Conversation.all.includes(:participants, :messages)

      respond_to do |format|
        format.html # renders app/views/polylingo_chat/conversations/index.html.erb
        format.json { render json: @conversations.map { |c| conversation_json(c) } }
      end
    end

    # GET /polylingo_chat/conversations/:id
    def show
      respond_to do |format|
        format.html # renders app/views/polylingo_chat/conversations/show.html.erb
        format.json { render json: conversation_json(@conversation, include_messages: true) }
      end
    end

    # POST /polylingo_chat/conversations
    def create
      @conversation = Conversation.new(conversation_params)

      if @conversation.save
        # Add participants if provided
        if params[:participant_ids].present?
          add_participants_from_params(@conversation)
        end

        respond_to do |format|
          format.html { redirect_to polylingo_chat_conversation_path(@conversation), notice: 'Conversation created successfully.' }
          format.json { render json: conversation_json(@conversation), status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /polylingo_chat/conversations/:id
    def update
      if @conversation.update(conversation_params)
        respond_to do |format|
          format.html { redirect_to polylingo_chat_conversation_path(@conversation), notice: 'Conversation updated successfully.' }
          format.json { render json: conversation_json(@conversation) }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /polylingo_chat/conversations/:id
    def destroy
      @conversation.destroy

      respond_to do |format|
        format.html { redirect_to polylingo_chat_conversations_path, notice: 'Conversation deleted successfully.' }
        format.json { head :no_content }
      end
    end

    private

    def set_conversation
      @conversation = Conversation.find(params[:id])
    end

    def conversation_params
      params.require(:conversation).permit(:title)
    end

    def add_participants_from_params(conversation)
      Array(params[:participant_ids]).each do |participant_data|
        type = participant_data[:type] || 'User'
        id = participant_data[:id]
        role = participant_data[:role]

        klass = type.constantize
        record = klass.find(id)
        conversation.add_participant(record, role: role)
      end
    end

    def conversation_json(conversation, include_messages: false)
      {
        id: conversation.id,
        title: conversation.title,
        created_at: conversation.created_at,
        updated_at: conversation.updated_at,
        participants: conversation.participants.map { |p| participant_json(p) },
        messages: include_messages ? conversation.messages.map { |m| message_json(m) } : []
      }
    end

    def participant_json(participant)
      {
        id: participant.id,
        type: participant.participantable_type,
        participant_id: participant.participantable_id,
        role: participant.role,
        name: participant.participantable.try(:name) || participant.participantable.try(:email)
      }
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
        created_at: message.created_at
      }
    end
  end
end
