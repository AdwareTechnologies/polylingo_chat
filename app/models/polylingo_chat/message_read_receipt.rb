module PolylingoChat
  class MessageReadReceipt < ApplicationRecord
    belongs_to :message, class_name: "PolylingoChat::Message"
    belongs_to :reader, polymorphic: true

    validates :message_id, uniqueness: { scope: [:reader_type, :reader_id] }
    validates :read_at, presence: true

    # Set read_at to current time if not provided
    before_validation :set_read_at, on: :create

    private

    def set_read_at
      self.read_at ||= Time.current
    end
  end
end
