# frozen_string_literal: true

module TributaryAuthorities
  # Factory Method para crear el adaptador apropiado según la configuración
  # Ejemplo de patrón para integración futura con entidades tributarias
  class Factory
    # Mapeo de países/entidades a sus adaptadores
    ADAPTERS = {
      'colombia' => 'TributaryAuthorities::DianAdapter',
      'other' => 'TributaryAuthorities::OtherAdapter'
    }.freeze

    class << self
      # Crea el adaptador apropiado según la configuración
      def create_adapter(invoice)
        adapter_class = get_adapter_class
        adapter_class.new(invoice)
      end

      # Retorna la clase del adaptador según la configuración
      def get_adapter_class
        country = ENV.fetch('TRIBUTARY_AUTHORITY_COUNTRY', 'other').downcase
        adapter_name = ADAPTERS[country] || ADAPTERS['other']
        
        adapter_name.constantize
      rescue NameError => e
        Rails.logger.error("[TributaryAuthoritiesFactory] Error cargando adaptador: #{e.message}")
        TributaryAuthorities::OtherAdapter
      end

      # Lista los adaptadores disponibles
      def available_adapters
        ADAPTERS.keys
      end
    end
  end
end

