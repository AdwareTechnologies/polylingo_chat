module PolylingoChat
  class Message < ApplicationRecord
    belongs_to :conversation, class_name: "PolylingoChat::Conversation"
    # Polymorphic sender - supports User, Vendor, Customer, etc.
    belongs_to :sender, polymorphic: true
    has_many :translations, class_name: "PolylingoChat::MessageTranslation", dependent: :destroy

    validates :body, presence: true

    after_create_commit :enqueue_translation_job

    # Get translation for a specific language
    def translation_for(language)
      # Return original if requesting source language
      return body if self.language == language

      # Find cached translation
      translation = translations.find_by(language: language)
      translation&.translated_text || body
    end

    # Helper method to get sender's name (works with any model that has a name method)
    def sender_name
      sender.try(:name) || sender.try(:full_name) || sender.try(:email) || "Unknown"
    end

    private

    def enqueue_translation_job
      PolylingoChat::TranslateJob.perform_later(id) if PolylingoChat.config.async
    end
  end
end
