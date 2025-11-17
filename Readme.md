# Polyglot — Real-time Multilingual Chat Engine for Rails

Polyglot is a plug-and-play Rails Engine that adds real-time chat to your Rails app. Use it as a **chat-only engine** or enable **AI-powered translation** for multilingual conversations.

Perfect for marketplaces, SaaS apps, CRMs, support systems, or global communities.

---

## ✨ Features

- 🔥 **Real-time chat** using ActionCable with Solid Cable (database-backed)
- 🚀 **One-command installer** — everything set up automatically
- 🌍 **Optional AI translation** - works with or without translation
- ⚙️ **Multi-provider support** — OpenAI, Anthropic Claude, or Google Gemini
- 🧩 **Rails Engine** — mounts directly inside your app
- 👥 **Conversations, Participants & Messages** models included
- 🔌 **Works with any ActiveJob backend** (Sidekiq, Solid Queue, Delayed Job, etc.)
- 🔐 **Secure & scoped** ActionCable channels
- 🧱 **Extendable architecture** (custom UI, custom providers, custom storage)
- 💾 **Built-in caching** support for translations
- 🧪 **RSpec testing** framework included
- 🗄️ **No Redis required** — uses Solid Cable for WebSocket persistence

---

## 📋 Requirements

- Ruby >= 2.7.0
- Rails >= 6.0
- A background job processor (Sidekiq, Solid Queue, or Delayed Job)
- **Optional:** AI API key (only if you want translation)

**Note:** Polyglot uses **Solid Cable** (database-backed ActionCable) by default, so Redis is optional.

---

## 🚀 Installation

### 1. Add the gem
```ruby
# Gemfile
gem "polyglot", github: "AdwareTechnologies/polyglot"

# Add a background job processor
gem 'sidekiq'  # or 'solid_queue' or 'delayed_job_active_record'
```

### 2. Install and generate
```bash
bundle install
bin/rails generate polyglot:install
bin/rails db:migrate
```

**The installer automatically:**
- ✅ Creates migrations for Conversations, Participants, and Messages
- ✅ Generates model files with associations
- ✅ Sets up ActionCable channels (PolyglotChatChannel)
- ✅ Creates JavaScript files for real-time chat
- ✅ Configures Solid Cable in `config/cable.yml`
- ✅ Downloads ActionCable ESM module to `vendor/javascript`
- ✅ Updates `config/routes.rb` with chat routes
- ✅ Updates `config/importmap.rb` with required pins
- ✅ Updates `app/javascript/application.js` with chat import
- ✅ Creates `config/initializers/polyglot.rb` for configuration

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

### 5. Configure Polyglot

Edit `config/initializers/polyglot.rb` (created by installer):

**Option A: Chat-Only Mode (No Translation)**
```ruby
Polyglot.configure do |config|
  # Leave api_key as nil for chat-only mode
  config.api_key = nil

  config.queue_adapter = :sidekiq
  config.async = true
end
```

**Option B: With AI Translation**
```ruby
Polyglot.configure do |config|
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

## 🎯 Usage

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
conversation = Conversation.create!(title: "Project Discussion")

# Add participants
Participant.create!(conversation: conversation, user: user1)
Participant.create!(conversation: conversation, user: user2)

# Send a message
Message.create!(
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
// It connects to PolyglotChatChannel and handles incoming messages

import consumer from "channels/consumer"

consumer.subscriptions.create({
  channel: "PolyglotChatChannel",
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

## 🏗️ How It Works

### Message Flow

1. User sends a message → saved to database
2. `Message#after_create_commit` enqueues job
3. Job runs in background via your ActiveJob adapter
4. **If API key present:** Message translated for each participant
5. **If no API key:** Original message used for all participants
6. Messages broadcast via ActionCable (using Solid Cable)
7. Recipients see messages in real-time

### Models

**Conversation** - Chat conversation with many participants and messages

**Participant** - Join table linking Users to Conversations

**Message** - Individual chat message with translation tracking

### Solid Cable (Database-Backed WebSockets)

Polyglot uses **Solid Cable** instead of Redis for ActionCable. Benefits:

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
  - [polyglot_translations, 10]
  - [default, 5]
```

**Solid Queue:**
```yaml
# config/solid_queue.yml
workers:
  - queues: polyglot_translations
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

- 🐛 **Issues:** [GitHub Issues](https://github.com/shoaibmalik786/polyglot/issues)
- 📖 **Documentation:** [GitHub Wiki](https://github.com/shoaibmalik786/polyglot/wiki)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/shoaibmalik786/polyglot/discussions)

---

**Made with ❤️ for the global Rails community**
