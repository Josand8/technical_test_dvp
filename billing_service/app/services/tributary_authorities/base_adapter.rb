# frozen_string_literal: true

module TributaryAuthorities
  # Clase base abstracta para adaptadores de entidades tributarias
  # Implementa el patrón Factory Method para permitir integraciones futuras
  class BaseAdapter
    def initialize(invoice)
      @invoice = invoice
    end

    # Genera el documento electrónico tributario
    def generate_electronic_document
      raise NotImplementedError, "#{self.class} debe implementar #generate_electronic_document"
    end

    # Envía el documento a la entidad tributaria
    def submit_to_authority
      raise NotImplementedError, "#{self.class} debe implementar #submit_to_authority"
    end

    # Valida el formato según las reglas de la entidad
    def validate_format
      raise NotImplementedError, "#{self.class} debe implementar #validate_format"
    end

    # Obtiene el estado de la factura en la entidad
    def check_status
      raise NotImplementedError, "#{self.class} debe implementar #check_status"
    end

    # Cancela o anula la factura
    def cancel_invoice(reason:)
      raise NotImplementedError, "#{self.class} debe implementar #cancel_invoice"
    end

    protected

    attr_reader :invoice
  end
end

