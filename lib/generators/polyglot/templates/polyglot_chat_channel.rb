class PolyglotChatChannel < ApplicationCable::Channel
  def subscribed
    # stream for the current user
    stream_from "polyglot_recipient_#{current_user.id}"
  end

  def receive(data)
    # data: { message: 'Hola', conversation_id: 1 }
    message_text = data['message']
    conversation = Conversation.find(data['conversation_id'])

    msg = Message.create!(conversation: conversation, sender: current_user, body: message_text, language: current_user.preferred_language)
    # enqueue translation job
    Polyglot::TranslateJob.perform_async(msg.id)

    # broadcast original to sender's stream if you want
    ActionCable.server.broadcast("polyglot_recipient_#{current_user.id}", { message: message_text, original: message_text, sender_id: current_user.id, message_id: msg.id, original:true })
  end
end
