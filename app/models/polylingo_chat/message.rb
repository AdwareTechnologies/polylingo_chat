module PolylingoChat
  class Message < ApplicationRecord
    belongs_to :conversation, class_name: "PolylingoChat::Conversation"
    # Polymorphic sender - supports User, Vendor, Customer, etc.
    belongs_to :sender, polymorphic: true
    has_many :translations, class_name: "PolylingoChat::MessageTranslation", dependent: :destroy
    has_many :read_receipts, class_name: "PolylingoChat::MessageReadReceipt", dependent: :destroy

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

    # Mark message as read by a specific reader
    def mark_as_read_by(reader)
      read_receipts.find_or_create_by(reader: reader)
    end

    # Check if message has been read by a specific reader
    def read_by?(reader)
      read_receipts.exists?(reader: reader)
    end

    # Check if message is unread by a specific reader
    def unread_by?(reader)
      !read_by?(reader)
    end

    # Get the timestamp when message was read by a specific reader
    def read_at_by(reader)
      read_receipts.find_by(reader: reader)&.read_at
    end

    # Get all readers who have read this message
    def readers
      read_receipts.includes(:reader).map(&:reader)
    end

    # Scope to get unread messages for a specific reader
    scope :unread_by, ->(reader) {
      left_joins(:read_receipts)
        .where.not(
          id: MessageReadReceipt.where(
            reader_type: reader.class.name,
            reader_id: reader.id
          ).select(:message_id)
        )
    }

    # Scope to get read messages for a specific reader
    scope :read_by, ->(reader) {
      joins(:read_receipts)
        .where(polylingo_chat_message_read_receipts: {
          reader_type: reader.class.name,
          reader_id: reader.id
        })
    }

    private

    def enqueue_translation_job
      PolylingoChat::TranslateJob.perform_later(id) if PolylingoChat.config.async
    end
  end
end
