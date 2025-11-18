# Changelog

All notable changes to PolylingoChat will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2025-01-18

### Added - DATABASE-BACKED TRANSLATION CACHING 🚀
- **Major Performance & Cost Improvement**: Translations now cached in database
  - New `polylingo_chat_message_translations` table stores all translations permanently
  - Translations cached after first translation job runs
  - **Zero AI API calls** for cached translations on subsequent retrievals
  - New `PolylingoChat::MessageTranslation` model with unique index on `[message_id, language]`
  - New `Message#translation_for(language)` helper method to retrieve cached translations

- **Enhanced JSON API with Translation Support**:
  - Added `?lang=` query parameter to all endpoints (e.g., `?lang=es` for Spanish)
  - All message responses now include `available_translations` array showing all cached translations
  - When `?lang=` specified, response includes `translation` and `translation_language` fields
  - Cached translations load instantly from database (no AI API calls)

- **API-Only Mode Improvements**:
  - CSRF protection automatically disabled for JSON requests (`protect_from_forgery with: :null_session`)
  - Full support for API-only Rails applications
  - POST requests work without CSRF tokens when Content-Type is `application/json`

### Changed
- Updated `TranslateJob` to save translations to database in addition to broadcasting
- Modified `ConversationsController#show` and `MessagesController#index` to support `?lang=` parameter
- Enhanced `message_json` helper methods to include cached translations in API responses
- Improved message flow to cache translations for all participant languages

### Performance Impact
- **Massive cost savings**: Translate once, retrieve unlimited times at zero cost
- **100x+ faster retrieval**: Database queries vs AI API calls
- **Scales effortlessly**: Database caching scales with your infrastructure
- **Works offline**: No dependency on AI service availability for viewing cached translations

### Database Schema
```ruby
create_table :polylingo_chat_message_translations do |t|
  t.references :message, null: false
  t.string :language, null: false     # ISO 639-1 code (e.g., 'es', 'fr')
  t.text :translated_text, null: false
  t.timestamps

  t.index [:message_id, :language], unique: true
end
```

## [0.3.1] - 2025-01-17

### Changed - MAJOR REFACTORING
- **Proper Rails Engine Architecture** (similar to Devise)
  - Models, controllers, views, and jobs now live in the gem's `app/` directory
  - Installer only generates migrations, config, channels, and JavaScript
  - Apps can override any file by creating it in their own `app/` directory
  - No more file generation into host app - cleaner and more maintainable

- **Universal Controller Support**: Controllers now support both HTML and JSON formats
  - Added `respond_to` blocks to handle both full-stack Rails apps and API-only requests
  - HTML format renders ERB views for traditional Rails apps
  - JSON format returns structured data for API consumers

- **View Templates**: Added basic ERB view templates in gem
  - `index.html.erb`: List all conversations with participants and message counts
  - `show.html.erb`: Display conversation with real-time chat interface
  - Views include inline CSS for quick setup
  - Views work with ActionCable for real-time updates

### Why This Change?
- **Standard Rails Engine Pattern**: Works like Devise - files stay in gem, override when needed
- **Less Duplication**: No more copying files to every app that uses the gem
- **Easier Updates**: When gem is updated, apps get updates automatically
- **Better Maintainability**: One source of truth for all code
- **Cleaner Apps**: Host apps only contain overrides and configuration
- **Universal Compatibility**: Same gem works for full-stack and API-only apps

## [0.3.0] - 2025-01-17

### Changed - BREAKING
- **Complete Namespacing**: Everything is now fully namespaced under `PolylingoChat::`
  - **Models**: `Conversation` → `PolylingoChat::Conversation`, `Participant` → `PolylingoChat::Participant`, `Message` → `PolylingoChat::Message`
  - **Controllers**: `ConversationsController` → `PolylingoChat::ConversationsController`, `MessagesController` → `PolylingoChat::MessagesController`
  - **Routes**: `/api/conversations` → `/polylingo_chat/conversations`
  - **Tables**: Rails now automatically infers table names from namespace (`polylingo_chat_conversations`, `polylingo_chat_participants`, `polylingo_chat_messages`)
- Models generated in `app/models/polylingo_chat/` directory
- Controllers generated in `app/controllers/polylingo_chat/` directory (works for both API-only and full-stack)
- Removed explicit `self.table_name` declarations (Rails infers from namespace)
- Controllers work for both API-only and full-stack Rails applications

### Why This Change?
- **Zero Conflicts**: Completely eliminates any possibility of naming conflicts with existing application code
- **Better Organization**: All PolylingoChat code is clearly isolated in its own namespace
- **Rails Conventions**: Follows Rails naming conventions where namespace determines table names
- **Universal Compatibility**: Same controllers work for API-only and full-stack apps

### Migration Guide
If you're upgrading from v0.2.x:
1. Update model references to use full namespace:
   ```ruby
   # Old
   Conversation.create!(title: "Chat")

   # New
   PolylingoChat::Conversation.create!(title: "Chat")
   ```

2. Update API endpoint URLs:
   ```ruby
   # Old
   POST /api/conversations

   # New
   POST /polylingo_chat/conversations
   ```

## [0.2.1] - 2025-01-17

### Changed
- **Table Name Prefixes**: All database tables now use `polylingo_chat_` prefix to avoid conflicts
  - `conversations` → `polylingo_chat_conversations`
  - `participants` → `polylingo_chat_participants`
  - `messages` → `polylingo_chat_messages`
- Migration class names updated to reflect prefixed table names
- Models explicitly set custom table names using `self.table_name`
- Updated documentation to reflect prefixed table names

### Why This Change?
This prevents table name conflicts when integrating PolylingoChat into applications that already have `conversations`, `participants`, or `messages` tables.

## [0.2.0] - 2025-01-17

### Added
- **API-Only Mode Support**: Full support for Rails API applications
  - Auto-detection of API-only Rails apps
  - `--api-only` flag for explicit API-only installation
  - API controllers: `Api::ConversationsController` and `Api::MessagesController`
  - RESTful JSON endpoints for conversations and messages
  - Skips ActionCable/frontend setup for API-only mode

- **Polymorphic Associations**: Support for multiple participant types
  - Participants can now be any model type (User, Vendor, Customer, Admin, etc.)
  - Messages can be sent by any model type via polymorphic `sender` association
  - New `Conversation` methods:
    - `participantables` - Get all participants regardless of type
    - `participantables_of_type(klass)` - Get participants of specific type
    - `add_participant(record, role: nil)` - Add any model as participant
    - `includes_participant?(record)` - Check participant membership
  - New `Message#sender_name` helper that works with any sender type
  - Backward compatibility maintained with `users` method

- **Enhanced Documentation**:
  - API-only installation and usage guide
  - Polymorphic associations examples
  - API endpoint documentation with request/response examples
  - Updated use cases for API-only and multi-model scenarios

### Changed
- `TranslateJob` updated to work with polymorphic associations
- Participant model now uses `participantable` polymorphic association
- Message model now uses `sender` polymorphic association
- Installer detects API-only mode and adjusts setup accordingly
- Routes updated to support both full-stack and API-only modes

### Backward Compatibility
- All existing functionality preserved
- `Participant#user` and `Participant#user=` methods still work
- `Conversation#users` method still works (returns User participants only)
- Existing installations will continue to work without changes

## [0.1.1] - 2025-01-15

### Fixed
- Fixed deprecated `ActiveJob::Base` pattern (changed to `ApplicationJob`)
- Fixed installer bug with duplicate "chat" in channel filename
- Fixed bare `rescue` statements (changed to `rescue StandardError => e`)
- Removed 10 legacy template files
- Updated gem dependencies with proper version constraints

### Changed
- Improved error handling with proper logging in 6 locations
- Updated gemspec with constrained dependency versions

### Added
- Created AUDIT_REPORT.md documenting all code quality improvements

## [0.1.0] - 2025-01-10

### Added
- Initial release of PolylingoChat
- Real-time chat using ActionCable with Solid Cable
- Optional AI-powered translation (OpenAI, Anthropic Claude, Google Gemini)
- One-command installer
- Chat-only mode (works without API key)
- Conversation, Participant, and Message models
- Background job support (Sidekiq, Solid Queue, Delayed Job)
- Automatic ActionCable setup
- JavaScript integration
- Configurable translation settings
- RSpec testing framework
- Comprehensive documentation

[0.3.0]: https://github.com/AdwareTechnologies/polylingo_chat/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/AdwareTechnologies/polylingo_chat/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/AdwareTechnologies/polylingo_chat/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/AdwareTechnologies/polylingo_chat/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AdwareTechnologies/polylingo_chat/releases/tag/v0.1.0
