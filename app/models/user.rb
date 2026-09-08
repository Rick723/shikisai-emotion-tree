class User < ApplicationRecord
  # Password reset behavior is implemented in a later issue.
  has_secure_password reset_token: false

  has_many :emotion_records, dependent: :destroy

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 20 }
  validates :email, presence: true, length: { maximum: 255 },
    format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  private

  def normalize_email
    self.email = email&.downcase
  end
end
