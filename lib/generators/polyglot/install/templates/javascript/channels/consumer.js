// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

// Pass user_id as a query parameter for authentication
const getWebSocketURL = () => {
  const userId = window.currentUserId
  if (userId) {
    return `/cable?user_id=${userId}`
  }
  return "/cable"
}

export default createConsumer(getWebSocketURL())
