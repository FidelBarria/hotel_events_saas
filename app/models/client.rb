class Client < ApplicationRecord
  has_many :events, dependent: :restrict_with_error

  before_validation :normalize_cnpj

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :cnpj, uniqueness: true, allow_blank: true
  validates :cnpj, format: { with: /\A\d{14}\z/, message: "deve conter 14 dígitos" }, allow_blank: true

  def formatted_cnpj
    return if cnpj.blank?

    cnpj.gsub(/\A(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})\z/, '\\1.\\2.\\3/\\4-\\5')
  end

  private

  def normalize_cnpj
    self.cnpj = cnpj.present? ? cnpj.to_s.gsub(/\D/, "") : nil
  end
end
