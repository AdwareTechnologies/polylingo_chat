class PolylinguoChatChannel < ApplicationCable::Channel
  def subscribed
    conversation_id = params[:conversation_id]

    # Subscribe to conversation-level channel for demo
    stream_from "conversation_#{conversation_id}"

    # Also subscribe to user-specific channel for production use
    stream_from "polylingo_chat_recipient_#{current_user.id}"
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
  end
end
