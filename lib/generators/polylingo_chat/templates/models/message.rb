class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'

  validates :body, presence: true

  after_create_commit :enqueue_translation_job

  private

  def enqueue_translation_job
    PolylingoChat::TranslateJob.perform_later(id) if PolylingoChat.config.async
  end
end
