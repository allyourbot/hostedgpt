class Message < ApplicationRecord
  include DocumentImage, Version, Cancellable, Toolable

  belongs_to :assistant
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", inverse_of: :message, optional: true
  belongs_to :run, optional: true
  has_one :latest_assistant_message_for, class_name: "Conversation", inverse_of: :last_assistant_message, dependent: :nullify

  enum role: %w[user assistant tool].index_by(&:to_sym)

  delegate :user, to: :conversation

  attribute :role, default: :user

  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }, prepend: true

  validates :role, presence: true
  validates :content_text, presence: true, unless: :assistant?
  validate  :validate_conversation,  if: -> { conversation.present? && Current.user }
  validate  :validate_assistant,     if: -> { assistant.present? && Current.user }

  after_create :start_assistant_reply, if: :user?
  after_create :set_last_assistant_message, if: :assistant?
  after_save :update_assistant_on_conversation, if: -> { assistant.present? && conversation.present? }

  scope :ordered, -> { latest_version_for_conversation }

  def name
    case role
    when "user" then user.first_name[/\A[a-zA-Z0-9_-]+/]
    when "assistant" then assistant.name[/\A[a-zA-Z0-9_-]+/]
    end
  end

  def finished?
    processed? &&
      (content_text.present? || content_tool_calls.present?)
  end

  def not_finished?
    !finished?
  end

  private

  def create_conversation
    self.conversation = Conversation.create!(user: Current.user, assistant: assistant)
  end

  def validate_conversation
    errors.add(:conversation) unless conversation.user == Current.user
  end

  def validate_assistant
    errors.add(:assistant) unless assistant.user == Current.user
  end

  def start_assistant_reply
    m = conversation.messages.create!(
      assistant: assistant,
      role: :assistant,
      content_text: nil,
      version: version,
      index: index+1
    )
  end

  def set_last_assistant_message
    conversation.update!(last_assistant_message: self)
  end

  def update_assistant_on_conversation
    return if conversation.assistant == assistant
    conversation.update!(assistant: assistant)
  end
end
