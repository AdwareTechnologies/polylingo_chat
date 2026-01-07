# Read Receipts API Documentation

This document describes the read/unread message tracking API endpoints for PolylingoChat.

## Overview

The read receipts feature provides per-participant tracking of message read status. Each participant can independently track which messages they have read.

## Authentication

All read receipt endpoints require authentication via `current_user`. Ensure your application implements the `current_user` method in your controllers.

---

## Automatic Read Tracking

Messages are automatically marked as read when:
- Viewing a conversation: `GET /polylingo_chat/conversations/:id`
- Fetching messages: `GET /polylingo_chat/conversations/:conversation_id/messages`

**Note:** Your own messages are never marked as read (only messages from other participants).

---

## API Endpoints

### 1. Get Conversations with Unread Counts

**Endpoint:** `GET /polylingo_chat/conversations.json`

**Description:** Lists all conversations with unread message counts for the current user.

**Response:**
```json
[
  {
    "id": 1,
    "title": "Project Discussion",
    "created_at": "2025-01-07T10:00:00Z",
    "updated_at": "2025-01-07T12:30:00Z",
    "unread_count": 5,
    "participants": [
      {
        "id": 1,
        "type": "User",
        "participant_id": 123,
        "role": "member",
        "name": "John Doe"
      }
    ],
    "messages": []
  }
]
```

**Usage Example:**
```bash
curl -X GET "http://localhost:3000/polylingo_chat/conversations.json" \
  -H "Content-Type: application/json"
```

---

### 2. Get Conversation with Messages and Read Status

**Endpoint:** `GET /polylingo_chat/conversations/:id.json`

**Description:** Retrieves a conversation with all messages. Automatically marks messages as read.

**Response:**
```json
{
  "id": 1,
  "title": "Project Discussion",
  "created_at": "2025-01-07T10:00:00Z",
  "updated_at": "2025-01-07T12:30:00Z",
  "unread_count": 0,
  "participants": [...],
  "messages": [
    {
      "id": 100,
      "body": "Hello team!",
      "language": "en",
      "sender_type": "User",
      "sender_id": 456,
      "sender_name": "Jane Smith",
      "read": true,
      "read_at": "2025-01-07T12:35:00Z",
      "created_at": "2025-01-07T10:15:00Z",
      "available_translations": [...]
    }
  ]
}
```

**Usage Example:**
```bash
curl -X GET "http://localhost:3000/polylingo_chat/conversations/1.json" \
  -H "Content-Type: application/json"
```

---

### 3. Get Messages for a Conversation

**Endpoint:** `GET /polylingo_chat/conversations/:conversation_id/messages.json`

**Description:** Retrieves all messages for a conversation. Automatically marks messages as read.

**Query Parameters:**
- `lang` (optional): ISO 639-1 language code for translations (e.g., 'es', 'fr')

**Response:**
```json
[
  {
    "id": 100,
    "body": "Hello team!",
    "language": "en",
    "translated_body": null,
    "translated": false,
    "sender_type": "User",
    "sender_id": 456,
    "sender_name": "Jane Smith",
    "conversation_id": 1,
    "read": true,
    "read_at": "2025-01-07T12:35:00Z",
    "created_at": "2025-01-07T10:15:00Z",
    "updated_at": "2025-01-07T10:15:00Z",
    "available_translations": []
  }
]
```

**Usage Example:**
```bash
curl -X GET "http://localhost:3000/polylingo_chat/conversations/1/messages.json?lang=es" \
  -H "Content-Type: application/json"
```

---

### 4. Mark Individual Message as Read

**Endpoint:** `POST /polylingo_chat/conversations/:conversation_id/messages/:id/mark_as_read`

**Description:** Explicitly marks a specific message as read by the current user.

**Use Cases:**
- Manual read tracking in API-only apps
- Marking messages as read without fetching the conversation
- Custom read receipt logic

**Response:**
```json
{
  "message": "Message marked as read",
  "read_at": "2025-01-07T12:40:00Z",
  "message_id": 100
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `422 Unprocessable Entity`: Attempting to mark own message as read

**Usage Example:**
```bash
curl -X POST "http://localhost:3000/polylingo_chat/conversations/1/messages/100/mark_as_read" \
  -H "Content-Type: application/json"
```

---

### 5. Mark All Messages as Read in Conversation

**Endpoint:** `POST /polylingo_chat/conversations/:id/mark_all_read`

**Description:** Marks all unread messages in a conversation as read for the current user.

**Use Cases:**
- "Mark all as read" button in UI
- Bulk read operations
- Clearing notification badges

**Response:**
```json
{
  "message": "All messages marked as read",
  "conversation_id": 1,
  "marked_count": 5
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated

**Usage Example:**
```bash
curl -X POST "http://localhost:3000/polylingo_chat/conversations/1/mark_all_read" \
  -H "Content-Type: application/json"
```

---

### 6. Get Unread Count for Conversation

**Endpoint:** `GET /polylingo_chat/conversations/:id/unread_count`

**Description:** Retrieves the unread message count for a specific conversation without marking messages as read.

**Use Cases:**
- Displaying unread counts without affecting read status
- Notification badges
- Checking for new messages without opening conversation

**Response:**
```json
{
  "conversation_id": 1,
  "unread_count": 5
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated

**Usage Example:**
```bash
curl -X GET "http://localhost:3000/polylingo_chat/conversations/1/unread_count" \
  -H "Content-Type: application/json"
```

---

## Model Methods (Ruby API)

For server-side usage in your Rails application:

### Message Model

```ruby
message = PolylingoChat::Message.find(1)
user = User.find(1)

# Mark message as read
message.mark_as_read_by(user)

# Check if read
message.read_by?(user)           # => true/false
message.unread_by?(user)         # => true/false

# Get read timestamp
message.read_at_by(user)         # => DateTime or nil

# Get all readers
message.readers                  # => Array of reader objects

# Query scopes
PolylingoChat::Message.unread_by(user)
PolylingoChat::Message.read_by(user)
```

### Conversation Model

```ruby
conversation = PolylingoChat::Conversation.find(1)
user = User.find(1)

# Get unread count
conversation.unread_messages_count_for(user)  # => Integer

# Check for unread messages
conversation.has_unread_messages_for?(user)   # => true/false
```

---

## API-Only Application Example

Here's a complete example for an API-only mobile app:

```javascript
// Fetch conversations with unread counts
async function getConversations() {
  const response = await fetch('/polylingo_chat/conversations.json');
  const conversations = await response.json();

  conversations.forEach(conv => {
    console.log(`${conv.title}: ${conv.unread_count} unread`);
  });

  return conversations;
}

// Open conversation (auto-marks as read)
async function openConversation(conversationId) {
  const response = await fetch(`/polylingo_chat/conversations/${conversationId}.json`);
  const conversation = await response.json();

  // Messages are now marked as read
  return conversation;
}

// Mark specific message as read (manual control)
async function markMessageRead(conversationId, messageId) {
  const response = await fetch(
    `/polylingo_chat/conversations/${conversationId}/messages/${messageId}/mark_as_read`,
    { method: 'POST' }
  );

  return await response.json();
}

// Mark all as read
async function markAllRead(conversationId) {
  const response = await fetch(
    `/polylingo_chat/conversations/${conversationId}/mark_all_read`,
    { method: 'POST' }
  );

  const result = await response.json();
  console.log(`Marked ${result.marked_count} messages as read`);
}

// Check unread count without marking as read
async function checkUnreadCount(conversationId) {
  const response = await fetch(
    `/polylingo_chat/conversations/${conversationId}/unread_count`
  );

  const { unread_count } = await response.json();
  return unread_count;
}
```

---

## Best Practices

### For API-Only Applications

1. **Automatic vs Manual Tracking**: Choose one approach:
   - **Automatic**: Let GET requests mark messages as read automatically
   - **Manual**: Disable auto-marking and use explicit `mark_as_read` endpoints

2. **Polling vs WebSockets**:
   - Use `unread_count` endpoint for polling
   - Consider ActionCable for real-time updates

3. **Performance**:
   - The `unread_count` endpoint is optimized with database queries
   - Cache unread counts on client-side between updates

4. **User Experience**:
   - Update UI immediately after marking as read
   - Show read receipts (✓✓) only on sent messages
   - Display unread badges on conversation lists

### Read Receipt Indicators

For consistency with popular messaging apps:

- **Single check (✓)**: Message sent but not read
- **Double check (✓✓)**: Message read by at least one recipient
- **Color coding**: Gray for sent, Blue/Green for read

---

## Troubleshooting

### Messages not being marked as read

1. Ensure `current_user` is properly implemented
2. Check that you're authenticated in API requests
3. Verify the user is not the sender (own messages aren't marked as read)

### Performance issues with large conversations

1. Use pagination for messages
2. Cache unread counts
3. Use database indexes (already included in migration)

### Read receipts not showing

1. Verify migration has been run: `rails db:migrate`
2. Check that read receipts are being created: `PolylingoChat::MessageReadReceipt.count`
3. Ensure views are updated to latest version

---

## Database Schema

The read receipts feature uses the `polylingo_chat_message_read_receipts` table:

```ruby
create_table :polylingo_chat_message_read_receipts do |t|
  t.references :message, null: false
  t.references :reader, polymorphic: true, null: false
  t.datetime :read_at, null: false
  t.timestamps
end

# Indexes for performance
add_index :polylingo_chat_message_read_receipts,
  [:message_id, :reader_type, :reader_id],
  unique: true
```

This ensures:
- One read receipt per message per reader
- Fast lookups by message or reader
- Support for any polymorphic reader type (User, Customer, etc.)
