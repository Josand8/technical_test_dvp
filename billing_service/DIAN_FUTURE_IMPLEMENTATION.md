# Integración Futura con Entidades Tributarias

## Descripción

Este documento describe la arquitectura preparada para integración futura con entidades tributarias como la **DIAN** (Colombia) u otros organismos equivalentes (puede ser de otros paises).

## Patrón de Diseño: Factory Method

Se implementó el patrón **Factory Method** para permitir agregar diferentes adaptadores de entidades tributarias sin modificar el código existente.

### Estructura

```
billing_service/app/services/tributary_authorities/
├── base_adapter.rb       # Clase abstracta con métodos requeridos
├── dian_adapter.rb       # Adaptador para DIAN Colombia
├── other_adapter.rb      # Adaptador genérico para otros países
└── factory.rb            # Factory que selecciona el adaptador apropiado
```

## Cómo Funciona

### 1. Clase Base (BaseAdapter)

Define los métodos que todo adaptador debe implementar:
- `generate_electronic_document` - Genera documento electrónico
- `submit_to_authority` - Envía a la entidad tributaria
- `validate_format` - Valida según reglas locales
- `check_status` - Consulta estado del documento
- `cancel_invoice` - Anula la factura

### 2. Factory

Selecciona automáticamente el adaptador según configuración:

```ruby
# Se configura con variable de entorno
ENV['TAX_AUTHORITY_COUNTRY'] = 'colombia'  # Usa DianAdapter
ENV['TAX_AUTHORITY_COUNTRY'] = 'other'     # Usa OtherAdapter

# Uso
invoice = Invoice.find(1)
adapter = TributaryAuthorities::Factory.create_adapter(invoice)
adapter.generate_electronic_document
```

### 3. Adaptadores Disponibles

| Adaptador | País/Entidad | Estado |
|-----------|--------------|--------|
| `DianAdapter` | Colombia/DIAN | Preparado (stub) |
| `OtherAdapter` | Genérico | Preparado (stub) |

## Integración en el Modelo Invoice

```ruby
# Ejemplo de uso futuro
invoice = Invoice.create!(...)

# Obtener adaptador
adapter = TributaryAuthorities::Factory.create_adapter(invoice)

# Generar documento tributario
adapter.generate_electronic_document

# Enviar a entidad
adapter.submit_to_authority

# Validar formato
adapter.validate_format

# Consultar estado
adapter.check_status

# Cancelar
adapter.cancel_invoice(reason: "Error en datos")
```

## Agregar Nueva Entidad Tributaria

Para agregar un nuevo país (ejemplo: México/SAT):

**Paso 1**: Crear adaptador
```ruby
# app/services/tributary_authorities/sat_adapter.rb
class SatAdapter < BaseAdapter
  def generate_electronic_document
    # Implementar según SAT
  end
  # ... otros métodos
end
```

**Paso 2**: Registrar en Factory
```ruby
# factory.rb
ADAPTERS = {
  'colombia' => 'TributaryAuthorities::DianAdapter',
  'mexico' => 'TributaryAuthorities::SatAdapter',  # ← Agregar
  'other' => 'TributaryAuthorities::OtherAdapter'
}
```

**Paso 3**: Configurar
```env
TAX_AUTHORITY_COUNTRY=mexico
```

¡Listo! El sistema usará automáticamente el nuevo adaptador.

## Beneficios del Patrón

✅ **Extensible**: Agregar nuevos adaptadores sin modificar código existente  
✅ **Mantenible**: Cada adaptador es independiente  
✅ **Flexible**: Cambiar entre adaptadores con configuración  
✅ **Escalable**: Soporta múltiples países/entidades

## Configuración

```env
# .env
TAX_AUTHORITY_COUNTRY=colombia  # colombia, mexico, peru, other
```

