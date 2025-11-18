# PolylingoChat — Real-time Multilingual Chat Engine for Rails

PolylingoChat is a plug-and-play Rails Engine that adds real-time chat to your Rails app. Use it as a **chat-only engine** or enable **AI-powered translation** for multilingual conversations.

Perfect for marketplaces, SaaS apps, CRMs, support systems, or global communities.

---

## ✨ Features

- 🔥 **Real-time chat** using ActionCable with Solid Cable (database-backed)
- 🚀 **One-command installer** — everything set up automatically
- 🌍 **Optional AI translation** - works with or without translation
- ⚙️ **Multi-provider support** — OpenAI, Anthropic Claude, or Google Gemini
- 🧩 **Rails Engine** — mounts directly inside your app
- 📱 **API-only mode** — works with Rails API applications (auto-detected)
- 👥 **Polymorphic associations** — supports multiple participant types (User, Vendor, Customer, etc.)
- 🔌 **Works with any ActiveJob backend** (Sidekiq, Solid Queue, Delayed Job, etc.)
- 🔐 **Secure & scoped** ActionCable channels
- 🧱 **Extendable architecture** (custom UI, custom providers, custom storage)
- 💾 **Database-backed translation caching** - translations stored and reused (zero API costs on retrieval)
- 🧪 **RSpec testing** framework included
- 🗄️ **No Redis required** — uses Solid Cable for WebSocket persistence

---

## 📋 Requirements

- Ruby >= 2.7.0
- Rails >= 6.0
- A background job processor (Sidekiq, Solid Queue, or Delayed Job)
- **Optional:** AI API key (only if you want translation)

**Note:** PolylingoChat uses **Solid Cable** (database-backed ActionCable) by default, so Redis is optional.

---

## 🚀 Installation

### 1. Add the gem
```ruby
# Gemfile
gem "polylingo_chat", github: "AdwareTechnologies/polylingo_chat"

# Add a background job processor
gem 'sidekiq'  # or 'solid_queue' or 'delayed_job_active_record'
```

### 2. Install and generate
```bash
bundle install
bin/rails generate polylingo_chat:install
bin/rails db:migrate
```

**The installer automatically:**
- ✅ Creates migrations for prefixed tables (`polylingo_chat_conversations`, `polylingo_chat_participants`, `polylingo_chat_messages`, `polylingo_chat_message_translations`)
- ✅ Generates namespaced models in `app/models/polylingo_chat/` directory
- ✅ Generates namespaced controllers in `app/controllers/polylingo_chat/` directory
- ✅ Sets up ActionCable channels (PolylinguoChatChannel) for full-stack apps
- ✅ Creates JavaScript files for real-time chat (full-stack only)
- ✅ Configures Solid Cable in `config/cable.yml` (full-stack only)
- ✅ Downloads ActionCable ESM module to `vendor/javascript` (full-stack only)
- ✅ Updates `config/routes.rb` with namespaced routes
- ✅ Updates `config/importmap.rb` with required pins (full-stack only)
- ✅ Updates `app/javascript/application.js` with chat import (full-stack only)
- ✅ Creates `config/initializers/polylingo_chat.rb` for configuration

**Note:** Everything is fully namespaced:
- Models: `PolylingoChat::Conversation`, `PolylingoChat::Participant`, `PolylingoChat::Message`
- Controllers: `PolylingoChat::ConversationsController`, `PolylingoChat::MessagesController`
- Tables: `polylingo_chat_conversations`, `polylingo_chat_participants`, `polylingo_chat_messages`
- Routes: `/polylingo_chat/conversations`, `/polylingo_chat/messages`

### 3. Configure ActiveJob
```ruby
# config/application.rb or config/environments/production.rb
config.active_job.queue_adapter = :sidekiq  # or :solid_queue, :delayed_job, :async
```

### 4. Add preferred_language to User (optional, only if using translation)
```bash
bin/rails generate migration AddPreferredLanguageToUsers preferred_language:string
bin/rails db:migrate
```

### 5. Configure PolylingoChat

Edit `config/initializers/polylingo_chat.rb` (created by installer):

**Option A: Chat-Only Mode (No Translation)**
```ruby
PolylingoChat.configure do |config|
  # Leave api_key as nil for chat-only mode
  config.api_key = nil

  config.queue_adapter = :sidekiq
  config.async = true
end
```

**Option B: With AI Translation**
```ruby
PolylingoChat.configure do |config|
  # Enable translation by setting API key
  config.provider = :openai  # or :anthropic, :gemini
  config.api_key = ENV['OPENAI_API_KEY']
  config.model = 'gpt-4o-mini'

  config.queue_adapter = :sidekiq
  config.default_language = 'en'
  config.cache_store = Rails.cache
  config.timeout = 15
  config.async = true
end
```

### 6. Configure ActionCable Authentication

The installer creates `app/channels/application_cable/connection.rb` with authentication logic. For development, it accepts `user_id` from WebSocket params:

```ruby
# app/channels/application_cable/connection.rb
def find_verified_user
  user_id = request.params[:user_id] || cookies.encrypted[:user_id]

  if user_id && (verified_user = User.find_by(id: user_id))
    verified_user
  else
    reject_unauthorized_connection
  end
end
```

The JavaScript consumer automatically passes `window.currentUserId` to authenticate. Make sure to set this in your views:

```erb
<!-- app/views/conversations/show.html.erb -->
<script>
  window.conversationId = <%= @conversation.id %>;
  window.currentUserId = <%= current_user.id %>;
</script>
```

**For production:** Replace the `find_verified_user` method with your actual authentication (Devise, session, JWT, etc.)

### 7. Start your background worker
```bash
bundle exec sidekiq  # or bin/rails solid_queue:start, or bin/rails jobs:work
```

---

## 🛠️ Advanced Installation

### API-Only Mode

PolylingoChat automatically detects Rails API applications and skips ActionCable/frontend setup. You can also explicitly enable API-only mode:

```bash
bin/rails generate polylingo_chat:install --api-only
bin/rails db:migrate
```

**API-only installation:**
- ✅ Creates migrations and models
- ✅ Creates API controllers (`Api::ConversationsController`, `Api::MessagesController`)
- ✅ Adds API routes under `/api` namespace
- ❌ Skips ActionCable channels
- ❌ Skips JavaScript files
- ❌ Skips Solid Cable setup

### Using Polymorphic Associations

PolylingoChat supports multiple participant types out of the box. Instead of limiting conversations to just Users, you can have Vendors, Customers, Admins, or any other model as participants.

#### Example: Multi-Model Participants

```ruby
# Create a conversation
conversation = PolylingoChat::Conversation.create!(title: "Support Ticket #123")

# Add different types of participants
user = User.find(1)
vendor = Vendor.find(5)
admin = Admin.find(2)

conversation.add_participant(user, role: 'customer')
conversation.add_participant(vendor, role: 'vendor')
conversation.add_participant(admin, role: 'support')

# Get all participants regardless of type
conversation.participantables
# => [#<User id: 1>, #<Vendor id: 5>, #<Admin id: 2>]

# Get participants of a specific type
conversation.participantables_of_type(Vendor)
# => [#<Vendor id: 5>]

# Backward compatibility - still works with User model
conversation.users  # Returns all User participants
```

#### Sending Messages with Polymorphic Senders

```ruby
# Any model can send a message
vendor = Vendor.find(5)
PolylingoChat::Message.create!(
  conversation: conversation,
  sender: vendor,  # Polymorphic - can be User, Vendor, Customer, etc.
  body: "We've shipped your order!"
)

# Message model automatically handles sender_name
message.sender_name  # Tries: name, full_name, email, or "Unknown"
```

---

## 🎯 Usage

### Using the API Endpoints

PolylingoChat provides JSON API endpoints that work for both API-only and full-stack Rails applications:

#### Create a Conversation

```bash
POST /polylingo_chat/conversations
Content-Type: application/json

{
  "conversation": {
    "title": "Project Discussion"
  },
  "participant_ids": [
    { "type": "User", "id": 1, "role": "owner" },
    { "type": "Vendor", "id": 5, "role": "participant" }
  ]
}
```

#### Send a Message

```bash
POST /polylingo_chat/conversations/:conversation_id/messages
Content-Type: application/json

{
  "message": {
    "body": "Hello! How are you?",
    "language": "en"
  },
  "sender_type": "User",
  "sender_id": 1
}
```

#### Get Conversation with Messages

```bash
# Get conversation without specific language
GET /polylingo_chat/conversations/:id.json

# Get conversation with Spanish translations
GET /polylingo_chat/conversations/:id.json?lang=es

Response:
{
  "id": 1,
  "title": "Project Discussion",
  "participants": [
    {
      "id": 1,
      "type": "User",
      "participant_id": 1,
      "role": "owner",
      "name": "John Doe"
    },
    {
      "id": 2,
      "type": "Vendor",
      "participant_id": 5,
      "role": "participant",
      "name": "ACME Corp"
    }
  ],
  "messages": [
    {
      "id": 1,
      "body": "Hello! How are you?",
      "language": "en",
      "translated": true,
      "translation": "¡Hola! ¿Cómo estás?",
      "translation_language": "es",
      "available_translations": [
        {"language": "es", "text": "¡Hola! ¿Cómo estás?"},
        {"language": "fr", "text": "Bonjour! Comment allez-vous?"}
      ],
      "sender_type": "User",
      "sender_id": 1,
      "sender_name": "John Doe",
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

**New in v0.4.0:** The `?lang=` parameter returns cached translations from the database with zero API calls. The `available_translations` array shows all cached translations for each message.

#### List All Messages in a Conversation

```bash
# Get messages without specific language
GET /polylingo_chat/conversations/:conversation_id/messages.json

# Get messages with French translations (from cache)
GET /polylingo_chat/conversations/:conversation_id/messages.json?lang=fr

Response:
[
  {
    "id": 1,
    "body": "Hello! How are you?",
    "language": "en",
    "translated": true,
    "translation": "Bonjour! Comment allez-vous?",
    "translation_language": "fr",
    "available_translations": [
      {"language": "es", "text": "¡Hola! ¿Cómo estás?"},
      {"language": "fr", "text": "Bonjour! Comment allez-vous?"}
    ],
    "sender_type": "User",
    "sender_id": 1,
    "sender_name": "John Doe",
    "conversation_id": 1,
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:05Z"
  }
]
```

### Full-Stack Usage (with ActionCable)

### 1. Set up your view

First, expose the conversation and user IDs to JavaScript in your chat view:

```erb
<!-- app/views/conversations/show.html.erb -->
<script>
  window.conversationId = <%= @conversation.id %>;
  window.currentUserId = <%= current_user.id %>;
</script>

<div id="messages">
  <!-- Messages will appear here via ActionCable -->
</div>
```

### 2. Send a message

```ruby
# Create a conversation
conversation = PolylingoChat::Conversation.create!(title: "Project Discussion")

# Add participants
conversation.add_participant(user1, role: 'member')
conversation.add_participant(user2, role: 'member')

# Send a message
PolylingoChat::Message.create!(
  conversation: conversation,
  sender: user1,
  body: "Hello! How are you?"
)
```

**What happens:**
- Message is saved to database
- Background job is enqueued automatically
- **Without API key:** Message is broadcast as-is to all participants
- **With API key:** Message is translated to each participant's preferred language
- All participants see the message in real-time via ActionCable

### 3. Real-time updates with ActionCable

The installer creates JavaScript files that handle real-time updates automatically. The key file is `app/javascript/chat.js`:

```javascript
// This file is automatically generated by the installer
// It connects to PolylinguoChatChannel and handles incoming messages

import consumer from "channels/consumer"

consumer.subscriptions.create({
  channel: "PolylinguoChatChannel",
  conversation_id: window.conversationId
}, {
  received(data) {
    // data.message - message text (translated if translation enabled)
    // data.original - original text
    // data.sender_id - sender's ID
    // data.translated - boolean (true if translation was used)
    console.log("Received:", data.message)
    console.log("Was translated:", data.translated)

    // The generated code automatically appends messages to #messages div
  }
})
```

**You don't need to write this code** — the installer creates it for you!

---

## 🌍 Translation (Optional)

### When to Use Translation

Translation is **optional**. Use it when:
- ✅ You have a global user base speaking different languages
- ✅ You want automatic message translation
- ✅ You're willing to pay for AI API usage

Skip translation when:
- ❌ All users speak the same language
- ❌ You want a simple chat without AI costs
- ❌ You'll handle translation elsewhere

### AI Providers

#### OpenAI
```ruby
config.provider = :openai
config.api_key = ENV['OPENAI_API_KEY']
config.model = 'gpt-4o-mini'  # Fast & cost-effective
```
Get key: https://platform.openai.com/api-keys

**Models:** `gpt-4o-mini`, `gpt-4o`, `gpt-3.5-turbo`

#### Anthropic Claude
```ruby
config.provider = :anthropic
config.api_key = ENV['ANTHROPIC_API_KEY']
config.model = 'claude-3-5-sonnet-20241022'
```
Get key: https://console.anthropic.com/

**Models:** `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-3-opus-20240229`

#### Google Gemini
```ruby
config.provider = :gemini
config.api_key = ENV['GOOGLE_API_KEY']
config.model = 'gemini-1.5-flash'
```
Get key: https://ai.google.dev/

**Models:** `gemini-1.5-flash`, `gemini-1.5-pro`

---

## ⚙️ Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | Symbol | `:openai` | AI provider (`:openai`, `:anthropic`, `:gemini`) |
| `api_key` | String | `nil` | API key - leave nil for chat-only mode |
| `model` | String | `'gpt-4o-mini'` | Model name for the provider |
| `queue_adapter` | Symbol | `nil` | Which ActiveJob adapter you're using (informational) |
| `default_language` | String | `'en'` | Default target language (ISO 639-1 code) |
| `cache_store` | Cache | `nil` | Rails cache store for caching translations |
| `async` | Boolean | `true` | Enable async processing via ActiveJob |
| `timeout` | Integer | `15` | API request timeout in seconds |

---

## 💾 Translation Caching (New in v0.4.0)

PolylingoChat now includes **database-backed translation caching** that dramatically reduces AI API costs and improves performance.

### How Translation Caching Works

1. **First Time Translation:**
   - User sends a message → AI translates it for each participant's language
   - Translations are saved to `polylingo_chat_message_translations` table
   - One translation per language per message

2. **Subsequent Retrievals:**
   - Page reloads, API calls → translations loaded from database
   - **Zero AI API calls** for cached translations
   - Instant response times

### Benefits

- ✅ **Massive cost savings** - Translate once, retrieve unlimited times
- ✅ **Lightning fast** - Database queries vs AI API calls
- ✅ **Works offline** - No dependency on AI service availability for viewing
- ✅ **Perfect for mobile** - Mobile apps get instant cached translations
- ✅ **Scales effortlessly** - Database caching scales with your infrastructure

### API Usage Example

```bash
# First time - translates and caches
curl -X POST http://localhost:3000/polylingo_chat/conversations/1/messages.json \
  -H "Content-Type: application/json" \
  -d '{"message":{"body":"Hello!"},"sender_type":"User","sender_id":1}'

# Response includes available_translations
{
  "id": 15,
  "body": "Hello!",
  "language": "en",
  "available_translations": [
    {"language": "es", "text": "¡Hola!"},
    {"language": "fr", "text": "Bonjour!"}
  ]
}

# Later retrievals - instant, no AI API calls
curl http://localhost:3000/polylingo_chat/conversations/1/messages.json?lang=es

# Returns cached Spanish translation immediately
{
  "translation": "¡Hola!",
  "translation_language": "es",
  "available_translations": [...]
}
```

### Database Schema

The `polylingo_chat_message_translations` table stores all cached translations:

```ruby
# Schema
create_table :polylingo_chat_message_translations do |t|
  t.references :message, null: false
  t.string :language, null: false     # ISO 639-1 code (e.g., 'es', 'fr')
  t.text :translated_text, null: false
  t.timestamps

  t.index [:message_id, :language], unique: true
end
```

---

## 🏗️ How It Works

### Message Flow

1. User sends a message → saved to database
2. `Message#after_create_commit` enqueues translation job
3. Job runs in background via your ActiveJob adapter
4. **If API key present:**
   - Message translated for each participant's language
   - Translations saved to `message_translations` table (cached)
   - Future retrievals use cached translations (zero API calls)
5. **If no API key:** Original message used for all participants
6. Messages broadcast via ActionCable (using Solid Cable)
7. Recipients see messages in real-time

### Models

All models are namespaced under `PolylingoChat::` and use the `polylingo_chat_` table prefix to prevent conflicts:

**PolylingoChat::Conversation** - Chat conversation with many participants and messages
- Table: `polylingo_chat_conversations`
- Location: `app/models/polylingo_chat/conversation.rb`
- `participantables` - Returns all participant records (polymorphic)
- `participantables_of_type(klass)` - Returns participants of a specific type
- `users` - Returns User participants (backward compatibility)
- `add_participant(record, role: nil)` - Adds any model as a participant
- `includes_participant?(record)` - Checks if a record is a participant

**PolylingoChat::Participant** - Join table with polymorphic associations
- Table: `polylingo_chat_participants`
- Location: `app/models/polylingo_chat/participant.rb`
- `participantable` - The actual participant (User, Vendor, Customer, etc.)
- Supports multiple model types via polymorphic association
- `user` alias for backward compatibility

**PolylingoChat::Message** - Individual chat message with translation tracking
- Table: `polylingo_chat_messages`
- Location: `app/models/polylingo_chat/message.rb`
- `sender` - Polymorphic association (User, Vendor, Customer, etc.)
- `sender_name` - Helper method that works with any sender type
- `translations` - Has many MessageTranslation records (cached translations)
- `translation_for(language)` - Returns cached translation or original body
- Automatic translation via background job if API key present

**PolylingoChat::MessageTranslation** - Cached translations (New in v0.4.0)
- Table: `polylingo_chat_message_translations`
- Location: `app/models/polylingo_chat/message_translation.rb`
- Stores one translation per language per message
- Unique index on `[message_id, language]`
- Dramatically reduces AI API costs by caching translations

### Solid Cable (Database-Backed WebSockets)

PolylingoChat uses **Solid Cable** instead of Redis for ActionCable. Benefits:

- ✅ **No Redis dependency** - One less service to manage
- ✅ **Message persistence** - WebSocket messages stored in database
- ✅ **Simpler deployment** - Works anywhere your database works
- ✅ **Better for development** - No need to run Redis locally
- ✅ **Cost-effective** - No separate Redis hosting required

Solid Cable uses your existing database (SQLite, PostgreSQL, MySQL) to store WebSocket messages with configurable retention:

```yaml
# config/cable.yml (configured automatically by installer)
development:
  adapter: solid_cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

The installer runs `bin/rails solid_cable:install` automatically, which creates the necessary migrations.

---

## 🧪 Running Tests

```bash
bundle exec rspec

# Current status:
# 29 examples, 0 failures
# Line Coverage: 91.02%
```

---

## 🚀 Performance Tips

### 1. Enable Caching (if using translation)
```ruby
config.cache_store = Rails.cache
```

### 2. Choose the Right Model
- **High-volume:** `gpt-4o-mini`, `claude-3-5-haiku`, `gemini-1.5-flash`
- **Quality:** `gpt-4o`, `claude-3-5-sonnet`, `gemini-1.5-pro`

### 3. Scale Your Job Processor

**Sidekiq:**
```yaml
# config/sidekiq.yml
:concurrency: 25
:queues:
  - [polylingo_chat_translations, 10]
  - [default, 5]
```

**Solid Queue:**
```yaml
# config/solid_queue.yml
workers:
  - queues: polylingo_chat_translations
    threads: 5
    processes: 3
```

---

## 🔒 Security

1. **API Keys:** Use environment variables, never commit
2. **User Scoping:** Ensure users can only access their conversations
3. **ActionCable Auth:** Secure channels with authentication
4. **Rate Limiting:** Consider limiting message creation
5. **Content Filtering:** Add profanity/spam filters if needed

---

## 💡 Use Cases

### Chat-Only Mode (No Translation)
Perfect for:
- Internal team chat
- Customer support (same language)
- Community forums
- Simple messaging features

### With Translation
Perfect for:
- Global marketplaces
- International teams
- Multi-language support systems
- Cross-border collaboration

### API-Only Mode
Perfect for:
- Mobile app backends (iOS, Android, React Native)
- SPA frontends (React, Vue, Angular)
- Microservices architectures
- Custom WebSocket implementations
- Multi-platform applications

### Polymorphic Participants
Perfect for:
- Marketplace chats (Buyers ↔ Sellers ↔ Support)
- Multi-tenant systems (Users ↔ Vendors ↔ Admins)
- B2B platforms (Companies ↔ Representatives)
- Healthcare apps (Patients ↔ Doctors ↔ Nurses)

---

## 🌐 Frontend Integration

PolylingoChat works seamlessly with frontend frameworks like **React**, **Next.js**, **Vue**, **Angular**, and more.

For a comprehensive guide on integrating with frontend applications, including:
- Complete API endpoint documentation
- React component examples with TypeScript
- Next.js integration patterns
- Real-time update strategies (polling, WebSocket, third-party services)
- Authentication patterns
- Translation query parameters

See the **[Frontend Integration Guide](FRONTEND_INTEGRATION.md)** for complete details.

### Quick Example (React + TypeScript)

```typescript
// Fetch messages with translation
const messages = await fetch(
  `/polylingo_chat/conversations/1/messages?translate=true&target_language=es`,
  {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  }
).then(r => r.json());

// Send a message
await fetch('/polylingo_chat/conversations/1/messages', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    message: { body: "Hello!" },
    sender_type: "User",
    sender_id: 1
  })
});
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Write tests for your changes
4. Commit and push
5. Open a Pull Request

---

## 📝 License

MIT License

---

## 👤 Author

**Shoaib Malik**
- Email: shoaib2109@gmail.com
- GitHub: [@shoaibmalik786](https://github.com/shoaibmalik786)

---

## 📞 Support

- 🐛 **Issues:** [GitHub Issues](https://github.com/shoaibmalik786/polylingo_chat/issues)
- 📖 **Documentation:** [GitHub Wiki](https://github.com/shoaibmalik786/polylingo_chat/wiki)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/shoaibmalik786/polylingo_chat/discussions)

---

**Made with ❤️ for the global Rails community**
