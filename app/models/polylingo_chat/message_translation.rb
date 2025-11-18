module PolylingoChat
  class MessageTranslation < ApplicationRecord
    belongs_to :message, class_name: "PolylingoChat::Message"

    validates :language, presence: true, uniqueness: { scope: :message_id }
    validates :translated_text, presence: true
  end
end
