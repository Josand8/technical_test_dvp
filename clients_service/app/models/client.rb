class Client < ApplicationRecord
  validates :name, presence: { message: "no puede estar vacío" },
                   length: { minimum: 2, maximum: 100, message: "debe tener entre 2 y 100 caracteres" }
  
  validates :email, presence: { message: "no puede estar vacío" },
                    uniqueness: { case_sensitive: false, message: "ya está registrado" },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "no tiene un formato válido" }
  
  validates :identification, uniqueness: { message: "ya está registrado" },
                             length: { maximum: 20, message: "no puede tener más de 20 caracteres" },
                             allow_blank: true
  
  validates :address, length: { maximum: 500, message: "no puede tener más de 500 caracteres" },
                      allow_blank: true

  before_save :normalize_email
  before_save :normalize_identification

  scope :by_name, ->(name) { where("UPPER(name) LIKE ?", "%#{name.upcase}%") }
  scope :by_email, ->(email) { where("UPPER(email) LIKE ?", "%#{email.upcase}%") }

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def normalize_identification
    self.identification = identification.strip if identification.present?
  end
end

