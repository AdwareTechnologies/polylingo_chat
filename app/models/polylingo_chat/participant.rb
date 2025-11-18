module PolylingoChat
  class Participant < ApplicationRecord
    # Polymorphic association - can belong to User, Vendor, Customer, etc.
    belongs_to :participantable, polymorphic: true
    belongs_to :conversation, class_name: "PolylingoChat::Conversation"

    validates :participantable_id, uniqueness: {
      scope: [:participantable_type, :conversation_id],
      message: "is already a participant in this conversation"
    }

    # Alias for backward compatibility and convenience
    def user
      participantable
    end

    def user=(value)
      self.participantable = value
    end
  end
end
