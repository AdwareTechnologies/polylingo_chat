class Conversation < ApplicationRecord
  has_many :participants, dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, dependent: :destroy

  validates :title, length: { maximum: 255 }, allow_blank: true
end
