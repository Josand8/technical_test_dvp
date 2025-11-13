class Invoice < ApplicationRecord
  include Auditable

  validates :invoice_number, presence: { message: "no puede estar vacío" },
                             uniqueness: { message: "ya está registrado" }
  
  validates :issue_date, presence: { message: "no puede estar vacío" }
  validate :issue_date_cannot_be_in_past
  
  validates :subtotal, presence: { message: "no puede estar vacío" },
                       numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" }
  
  validates :tax, numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" },
                  allow_nil: true
  
  validates :total, presence: { message: "no puede estar vacío" },
                    numericality: { greater_than_or_equal_to: 0, message: "debe ser mayor o igual a 0" }
  
  validates :status, inclusion: { in: %w[pending paid overdue cancelled], 
                                  message: "debe ser pending, paid, overdue o cancelled" }

  validates :client_id, presence: { message: "no puede estar vacío" }
  validate :client_must_exist

  before_validation :generate_invoice_number, on: :create
  before_validation :calculate_total
  before_validation :set_default_issue_date, on: :create
  before_validation :check_overdue_status

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where(status: 'overdue') }
  scope :by_client, ->(client_id) { where(client_id: client_id) }

  private

  def generate_invoice_number
    return if invoice_number.present?
    
    # Generar número de factura: INV-YYYYMMDD-XXXX
    date_part = Time.current.strftime("%Y%m%d")
    last_invoice = Invoice.where("invoice_number LIKE ?", "INV-#{date_part}-%").order(:invoice_number).last
    
    if last_invoice
      last_number = last_invoice.invoice_number.split('-').last.to_i
      new_number = last_number + 1
    else
      new_number = 1
    end
    
    self.invoice_number = "INV-#{date_part}-#{new_number.to_s.rjust(4, '0')}"
  end

  def calculate_total
    self.tax ||= 0.0
    self.total = (subtotal || 0.0) + (tax || 0.0)
  end

  def set_default_issue_date
    self.issue_date ||= Date.current
  end

  def client_must_exist
    return if client_id.blank?
    
    unless ClientsService.client_exists?(client_id)
      errors.add(:client_id, "el cliente no existe en el servicio de clientes")
    end
  end

  def check_overdue_status
    return if due_date.blank?
    return unless status == 'pending'
    
    if Date.current > due_date
      self.status = 'overdue'
    end
  end

  def issue_date_cannot_be_in_past
    return if issue_date.blank?
    
    if issue_date < Date.current
      errors.add(:issue_date, "no puede ser anterior a la fecha actual")
    end
  end
end

