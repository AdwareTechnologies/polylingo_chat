# PolylingoChat Quick Start Guide

Get real-time chat in 5 minutes! Translation is optional.

## Installation

### 1. Add gems
```ruby
# Gemfile
gem 'polylingo_chat', github: 'AdwareTechnologies/polylingo_chat'
gem 'sidekiq'  # or 'solid_queue' or 'delayed_job_active_record'
```

### 2. Install
```bash
bundle install
bin/rails generate polylingo_chat:install
bin/rails db:migrate
```

**The installer automatically creates:**
- Models (Conversation, Participant, Message)
- ActionCable channels (PolylinguoChatChannel)
- JavaScript files for real-time chat
- Routes, importmap, and configuration
- Solid Cable setup (database-backed WebSockets)

### 3. Configure ActiveJob
```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

### 4. Configure PolylingoChat

Edit `config/initializers/polylingo_chat.rb` (created by installer):

**For chat-only (no translation):**
```ruby
PolylingoChat.configure do |config|
  config.api_key = nil  # No translation
  config.queue_adapter = :sidekiq
  config.async = true
end
```

**For chat with translation:**
```ruby
PolylingoChat.configure do |config|
  config.provider = :openai
  config.api_key = ENV['OPENAI_API_KEY']
  config.model = 'gpt-4o-mini'
  config.queue_adapter = :sidekiq
  config.default_language = 'en'
  config.cache_store = Rails.cache
end
```

### 5. Set up authentication (required for WebSocket connection)

In your chat view, expose the conversation and user IDs to JavaScript:

```erb
<!-- app/views/conversations/show.html.erb -->
<script>
  window.conversationId = <%= @conversation.id %>;
  window.currentUserId = <%= current_user.id %>;
</script>
```

This allows ActionCable to authenticate and connect properly.

### 6. Add User language (optional, only if using translation)
```bash
bin/rails generate migration AddPreferredLanguageToUsers preferred_language:string
bin/rails db:migrate
```

### 7. Start worker
```bash
bundle exec sidekiq
```

## Usage

```ruby
# Create conversation
conversation = Conversation.create!(title: "Chat")
Participant.create!(conversation: conversation, user: user1)
Participant.create!(conversation: conversation, user: user2)

# Send message
Message.create!(
  conversation: conversation,
  sender: user1,
  body: "Hello!"
)
```

**Messages will automatically:**
- Broadcast in real-time via ActionCable
- Translate to each user's language (if API key configured)

**What happens:**
- ✅ Without API key: Message sent as-is to all users
- ✅ With API key: Message translated to each user's language

## API Keys (Optional)

Only needed if you want translation:
- **OpenAI:** https://platform.openai.com/api-keys
- **Anthropic:** https://console.anthropic.com/
- **Gemini:** https://ai.google.dev/

```bash
# .env
OPENAI_API_KEY=your-key-here
```

## Two Modes

| Mode | API Key | Use Case |
|------|---------|----------|
| **Chat-Only** | Not needed | Same-language chat, internal teams |
| **With Translation** | Required | Global users, multi-language support |

## Troubleshooting

**Jobs not running?**
```bash
# Check worker
bundle exec sidekiq

# Check ActiveJob
bin/rails console
> Rails.application.config.active_job.queue_adapter
```

**WebSocket not connecting?**
- Make sure `window.currentUserId` is set in your view
- Check browser console for connection errors
- Verify `app/channels/application_cable/connection.rb` exists
- Check Rails logs for "unauthorized connection" errors

**Messages not broadcasting?**
- Ensure background worker is running (`bundle exec sidekiq`)
- Check Rails logs for job execution
- Verify Solid Cable migrations ran: `bin/rails solid_cable:install`

**Need help?** See [README.md](README.md)

---

## 🔑 Key Features

- **No Redis required** - Uses Solid Cable (database-backed WebSockets)
- **Translation optional** - Works as chat-only or with AI translation
- **Plug and play** - One command installs everything
- **Production ready** - Tested, secure, and scalable

---

**Made with ❤️ by Shoaib Malik**
