# Frontend Integration Guide

This guide explains how to integrate PolylingoChat with frontend frameworks like React, Next.js, Vue, Angular, etc.

## Table of Contents
- [How Translation Works](#how-translation-works)
- [API Endpoints](#api-endpoints)
- [React Integration](#react-integration)
- [Next.js Integration](#nextjs-integration)
- [Real-time Updates](#real-time-updates)
- [Authentication](#authentication)

---

## How Translation Works

### Message Storage & Translation
When a message is created:

1. **Message is saved** to the database with the original `body`
2. **Background job is enqueued** automatically
3. **Language is detected** and saved to `language` column
4. **Default translation is created** and saved to `translated_body` column (in your `default_language`)
5. **Real-time translations** are created for each recipient based on their `preferred_language`
6. **Translations are broadcast** via ActionCable (if not API-only)

### Database Schema
```ruby
# polylingo_chat_messages table
{
  body: "Hello! How are you?",           # Original message
  language: "en",                        # Detected source language
  translated_body: "Hola! ¿Cómo estás?", # Translation in default_language
  translated: true,                       # Translation enabled/disabled
  sender_type: "User",                    # Polymorphic sender
  sender_id: 1
}
```

### On-the-Fly Translation
Frontend apps can request messages in any language using query parameters:

```bash
GET /polylingo_chat/conversations/1/messages?translate=true&target_language=es
```

This will:
- Use stored `translated_body` if target language matches `default_language`
- Translate on-the-fly if different language is requested
- Return original if translation is disabled

---

## API Endpoints

### Base URL
All endpoints are namespaced under `/polylingo_chat`

### Authentication
Add authentication headers to your API requests:
```javascript
headers: {
  'Authorization': 'Bearer YOUR_TOKEN',
  'Content-Type': 'application/json'
}
```

### Create Conversation
```http
POST /polylingo_chat/conversations
Content-Type: application/json

{
  "conversation": {
    "title": "Support Chat"
  },
  "participant_ids": [
    { "type": "User", "id": 1, "role": "customer" },
    { "type": "Vendor", "id": 5, "role": "support" }
  ]
}
```

Response:
```json
{
  "id": 1,
  "title": "Support Chat",
  "created_at": "2025-01-17T10:00:00Z",
  "participants": [...]
}
```

### Get Messages
```http
GET /polylingo_chat/conversations/:id/messages
```

**With Translation:**
```http
GET /polylingo_chat/conversations/:id/messages?translate=true&target_language=es
```

### Send Message
```http
POST /polylingo_chat/conversations/:id/messages
Content-Type: application/json

{
  "message": {
    "body": "Hello! How can I help you?",
    "language": "en"
  },
  "sender_type": "User",
  "sender_id": 1
}
```

Response:
```json
{
  "id": 10,
  "body": "Hello! How can I help you?",
  "language": "en",
  "translated_body": "¡Hola! ¿Cómo puedo ayudarte?",
  "translated": true,
  "sender_name": "John Doe",
  "created_at": "2025-01-17T10:05:00Z"
}
```

---

## React Integration

### Installation
```bash
npm install axios
# or
yarn add axios
```

### API Service
```typescript
// services/polylingoChatApi.ts
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: `${API_BASE_URL}/polylingo_chat`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add authentication token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const polylingoChatApi = {
  // Get conversation messages
  getMessages: async (conversationId: number, targetLanguage?: string) => {
    const params = targetLanguage
      ? { translate: 'true', target_language: targetLanguage }
      : {};

    const { data } = await api.get(`/conversations/${conversationId}/messages`, { params });
    return data;
  },

  // Send a message
  sendMessage: async (
    conversationId: number,
    body: string,
    senderType: string,
    senderId: number
  ) => {
    const { data } = await api.post(`/conversations/${conversationId}/messages`, {
      message: { body },
      sender_type: senderType,
      sender_id: senderId,
    });
    return data;
  },

  // Create conversation
  createConversation: async (title: string, participants: any[]) => {
    const { data } = await api.post('/conversations', {
      conversation: { title },
      participant_ids: participants,
    });
    return data;
  },

  // Get conversation details
  getConversation: async (conversationId: number) => {
    const { data } = await api.get(`/conversations/${conversationId}`);
    return data;
  },
};
```

### React Chat Component
```typescript
// components/Chat.tsx
import React, { useState, useEffect, useRef } from 'react';
import { polylingoChatApi } from '../services/polylingoChatApi';

interface Message {
  id: number;
  body: string;
  translated_body?: string;
  sender_name: string;
  sender_id: number;
  created_at: string;
}

interface ChatProps {
  conversationId: number;
  currentUserId: number;
  currentUserType: string;
  userLanguage?: string; // e.g., 'es', 'fr', 'de'
}

export const Chat: React.FC<ChatProps> = ({
  conversationId,
  currentUserId,
  currentUserType,
  userLanguage = 'en',
}) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load messages
  useEffect(() => {
    loadMessages();
    // Poll for new messages every 3 seconds
    const interval = setInterval(loadMessages, 3000);
    return () => clearInterval(interval);
  }, [conversationId, userLanguage]);

  const loadMessages = async () => {
    try {
      const data = await polylingoChatApi.getMessages(
        conversationId,
        userLanguage
      );
      setMessages(data);
      scrollToBottom();
    } catch (error) {
      console.error('Failed to load messages:', error);
    }
  };

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || loading) return;

    setLoading(true);
    try {
      await polylingoChatApi.sendMessage(
        conversationId,
        newMessage,
        currentUserType,
        currentUserId
      );
      setNewMessage('');
      // Reload messages to get the new one
      setTimeout(loadMessages, 1000); // Wait for background job
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setLoading(false);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="chat-container">
      <div className="messages">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`message ${
              message.sender_id === currentUserId ? 'sent' : 'received'
            }`}
          >
            <div className="message-sender">{message.sender_name}</div>
            <div className="message-body">
              {/* Show translated version if available */}
              {message.translated_body || message.body}
            </div>
            <div className="message-time">
              {new Date(message.created_at).toLocaleTimeString()}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="message-input">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Type a message..."
          disabled={loading}
        />
        <button type="submit" disabled={loading || !newMessage.trim()}>
          {loading ? 'Sending...' : 'Send'}
        </button>
      </form>
    </div>
  );
};
```

---

## Next.js Integration

### API Routes (Server-Side)
```typescript
// app/api/chat/[conversationId]/messages/route.ts
import { NextRequest, NextResponse } from 'next/server';
import axios from 'axios';

const RAILS_API_URL = process.env.RAILS_API_URL || 'http://localhost:3000';

export async function GET(
  request: NextRequest,
  { params }: { params: { conversationId: string } }
) {
  const searchParams = request.nextUrl.searchParams;
  const targetLanguage = searchParams.get('target_language');

  try {
    const { data } = await axios.get(
      `${RAILS_API_URL}/polylingo_chat/conversations/${params.conversationId}/messages`,
      {
        params: targetLanguage
          ? { translate: 'true', target_language: targetLanguage }
          : {},
        headers: {
          Authorization: request.headers.get('authorization'),
        },
      }
    );

    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch messages' },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: { conversationId: string } }
) {
  const body = await request.json();

  try {
    const { data } = await axios.post(
      `${RAILS_API_URL}/polylingo_chat/conversations/${params.conversationId}/messages`,
      body,
      {
        headers: {
          Authorization: request.headers.get('authorization'),
          'Content-Type': 'application/json',
        },
      }
    );

    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to send message' },
      { status: 500 }
    );
  }
}
```

### Server Component
```typescript
// app/chat/[id]/page.tsx
import { Chat } from '@/components/Chat';
import { getCurrentUser } from '@/lib/auth';

export default async function ChatPage({
  params,
}: {
  params: { id: string };
}) {
  const user = await getCurrentUser();

  return (
    <div className="container">
      <h1>Chat</h1>
      <Chat
        conversationId={parseInt(params.id)}
        currentUserId={user.id}
        currentUserType="User"
        userLanguage={user.preferred_language || 'en'}
      />
    </div>
  );
}
```

---

## Real-time Updates

### Option 1: Polling (Simplest)
Use `setInterval` to poll for new messages every few seconds:

```javascript
useEffect(() => {
  const interval = setInterval(() => {
    loadMessages();
  }, 3000); // Poll every 3 seconds

  return () => clearInterval(interval);
}, []);
```

**Pros:**
- Simple to implement
- Works everywhere
- No additional infrastructure needed

**Cons:**
- Not truly real-time
- Higher server load
- Delayed message delivery

### Option 2: WebSocket (Rails ActionCable from Frontend)
If your Rails API has ActionCable enabled, connect from your frontend:

```bash
npm install @rails/actioncable
```

```javascript
import { createConsumer } from '@rails/actioncable';

const cable = createConsumer('ws://localhost:3000/cable');

const subscription = cable.subscriptions.create(
  {
    channel: 'PolylinguoChatChannel',
    conversation_id: conversationId,
  },
  {
    received(data) {
      // New message received
      setMessages((prev) => [...prev, data]);
    },
  }
);
```

### Option 3: Third-Party Real-time Services
- **Pusher**: https://pusher.com
- **Ably**: https://ably.com
- **Socket.io**: https://socket.io

---

## Authentication

### JWT Token
Store JWT token and send with requests:

```javascript
// After login
localStorage.setItem('authToken', response.data.token);

// In API requests
headers: {
  'Authorization': `Bearer ${localStorage.getItem('authToken')}`
}
```

### Session Cookies
If using session-based auth, ensure cookies are sent:

```javascript
const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true, // Send cookies
});
```

### User Context
Store current user info:

```javascript
const user = {
  id: 1,
  type: 'User', // or 'Vendor', 'Admin', etc.
  preferred_language: 'es',
};
```

---

## Best Practices

1. **Error Handling**: Always handle API errors gracefully
2. **Loading States**: Show loading indicators during API calls
3. **Optimistic Updates**: Update UI immediately, sync with server
4. **Message Deduplication**: Use message IDs to prevent duplicates
5. **Retry Logic**: Implement retry for failed requests
6. **Offline Support**: Queue messages when offline
7. **Security**: Never expose API keys in frontend code
8. **Translation Caching**: Cache translations to reduce API calls

---

## Example: Full Chat App

See the complete example in the `/examples` directory:
- `/examples/react-chat` - React + TypeScript
- `/examples/nextjs-chat` - Next.js 14 App Router
- `/examples/vue-chat` - Vue 3 + Composition API

---

## Support

For more help:
- 📖 [Main README](README.md)
- 🐛 [Issues](https://github.com/AdwareTechnologies/polylingo_chat/issues)
- 💬 [Discussions](https://github.com/AdwareTechnologies/polylingo_chat/discussions)
