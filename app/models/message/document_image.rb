module Message::DocumentImage
  extend ActiveSupport::Concern

  included do
    has_many :documents, dependent: :destroy

    accepts_nested_attributes_for :documents
  end

  def has_document_image?(variant = nil)
    documents.present? && documents.first.has_image?(variant)
  end

  def document_image_path(variant, fallback: nil)
    return nil unless has_document_image?

    documents.first.image_path(variant, fallback)
  end
end
