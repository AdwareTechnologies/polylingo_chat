module PolylingoChat
  class Conversation < ApplicationRecord
    has_many :participants, class_name: "PolylingoChat::Participant", dependent: :destroy
    has_many :messages, class_name: "PolylingoChat::Message", dependent: :destroy

    validates :title, length: { maximum: 255 }, allow_blank: true

    # Get all participantable objects (User, Vendor, Customer, etc.)
    def participantables
      participants.map(&:participantable)
    end

    # Get participants of a specific type
    # Example: conversation.participantables_of_type(User)
    def participantables_of_type(klass)
      participants.where(participantable_type: klass.name).map(&:participantable)
    end

    # Backward compatibility - returns all User participants
    def users
      participantables_of_type(User) if defined?(User)
    end

    # Check if a record is a participant in this conversation
    def includes_participant?(record)
      participants.exists?(participantable: record)
    end

    # Add a participant to the conversation
    def add_participant(record, role: nil)
      participants.find_or_create_by(participantable: record) do |p|
        p.role = role if role
      end
    end

    # Get count of unread messages for a specific reader
    def unread_messages_count_for(reader)
      messages.unread_by(reader).where.not(sender: reader).count
    end

    # Check if conversation has unread messages for a specific reader
    def has_unread_messages_for?(reader)
      unread_messages_count_for(reader) > 0
    end
  end
end
