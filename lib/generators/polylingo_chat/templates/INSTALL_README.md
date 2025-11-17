## PolylingoChat Installation Complete!

### Next Steps:

**PolylingoChat can work in TWO modes:**
1. **Chat-Only Mode:** Real-time chat without translation (no API key needed)
2. **With Translation:** AI-powered translation (API key required)

---

### 1. Run migrations
```bash
bin/rails db:migrate
```

### 2. Configure ActiveJob

```ruby
# config/application.rb or config/environments/production.rb
config.active_job.queue_adapter = :sidekiq  # or :solid_queue, :delayed_job, :async
```

### 3. Install your background job processor

**Sidekiq:**
```ruby
# Gemfile
gem 'sidekiq'
```
Then: `bundle install && bundle exec sidekiq`

**Solid Queue:**
```ruby
# Gemfile
gem 'solid_queue'
```
Then: `bundle install && bin/rails solid_queue:install && bin/rails db:migrate && bin/rails solid_queue:start`

**Delayed Job:**
```ruby
# Gemfile
gem 'delayed_job_active_record'
```
Then: `bundle install && bin/rails generate delayed_job:active_record && bin/rails db:migrate && bin/rails jobs:work`

---

### 4. Configure PolylingoChat

Edit `config/initializers/polylingo_chat.rb`:

**Option A: Chat-Only (No Translation)**
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
  # Enable translation
  config.provider = :openai  # or :anthropic, :gemini
  config.api_key = ENV['POLYGLOT_API_KEY']
  config.model = 'gpt-4o-mini'

  config.queue_adapter = :sidekiq
  config.default_language = 'en'
  config.cache_store = Rails.cache
end
```

---

### 5. (Optional) Add preferred_language to User

**Only needed if using translation:**
```bash
bin/rails generate migration AddPreferredLanguageToUsers preferred_language:string
bin/rails db:migrate
```

---

### 6. Get API Key (Optional)

**Only if you want translation:**
- OpenAI: https://platform.openai.com/api-keys
- Anthropic: https://console.anthropic.com/
- Gemini: https://ai.google.dev/

```bash
# .env
POLYGLOT_API_KEY=your-key-here
```

---

### Testing

```ruby
conversation = Conversation.create!(title: "Test")
Participant.create!(conversation: conversation, user: user1)
Participant.create!(conversation: conversation, user: user2)

Message.create!(
  conversation: conversation,
  sender: user1,
  body: "Hello!"
)
```

- **Without API key:** Message sent as-is
- **With API key:** Message translated to each user's language

---

### Need Help?

- 📖 Documentation: https://github.com/shoaibmalik786/polylingo_chat
- 🐛 Issues: https://github.com/shoaibmalik786/polylingo_chat/issues
