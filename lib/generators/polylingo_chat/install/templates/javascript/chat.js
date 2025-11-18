import consumer from "channels/consumer"

console.log("Chat.js loaded!")

document.addEventListener('turbo:load', () => {
  console.log("Turbo loaded!")

  const conversationId = window.conversationId
  const currentUserId = window.currentUserId

  console.log("Conversation ID:", conversationId)
  console.log("Current User ID:", currentUserId)

  if (!conversationId) {
    console.log("No conversation ID found, skipping ActionCable subscription")
    return
  }

  // Subscribe to the PolylingoChatChannel
  console.log("Subscribing to PolylingoChatChannel...")
  const subscription = consumer.subscriptions.create(
    { channel: "PolylingoChatChannel", conversation_id: conversationId },
    {
      connected() {
        console.log("✓ Connected to PolylingoChatChannel!")
      },

      disconnected() {
        console.log("✗ Disconnected from PolylingoChatChannel")
      },

      received(data) {
        console.log("✓ Received message:", data)

        const messagesContainer = document.getElementById('messages')
        if (!messagesContainer) return

        // Check if message already exists in DOM (prevent duplicates)
        const existingMessage = messagesContainer.querySelector(`[data-message-id="${data.message_id}"]`)
        if (existingMessage) {
          console.log("Message already exists, skipping:", data.message_id)
          return
        }

        // Add new message
        const messageHtml = createMessageElement(data)
        messagesContainer.insertAdjacentHTML('beforeend', messageHtml)

        // Auto-scroll to bottom
        messagesContainer.scrollTop = messagesContainer.scrollHeight
      }
    }
  )

  // Auto-scroll messages to bottom on page load
  const messagesContainer = document.getElementById('messages')
  if (messagesContainer) {
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  function createMessageElement(data) {
    const isCurrentUser = data.sender_id === currentUserId
    const alignment = isCurrentUser ? 'justify-end' : 'justify-start'
    const bgColor = isCurrentUser ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-800'

    const translatedBadge = data.translated ? '<p class="text-xs mt-1 opacity-75">✓ Translated</p>' : ''
    const time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })

    return `
      <div class="message flex ${alignment}" data-message-id="${data.message_id}">
        <div class="${bgColor} rounded-lg px-4 py-2 max-w-xs">
          <p class="text-xs font-semibold mb-1">${escapeHtml(data.sender_name || 'Unknown')}</p>
          <p class="text-sm">${escapeHtml(data.message)}</p>
          ${translatedBadge}
          <p class="text-xs mt-1 opacity-75">${time}</p>
        </div>
      </div>
    `
  }

  function escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
})
