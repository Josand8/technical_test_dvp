# 📄 Servicio de Facturación

Microservicio para gestionar facturas del sistema. Permite crear, consultar y filtrar facturas, con integración automática con el servicio de clientes y auditoría.

## 🛠️ Tecnologías

- **Ruby**: 3.4.3
- **Rails**: 8.0.4
- **Base de datos**: Oracle Enhanced Adapter (~> 8.0.0)
- **Testing**: RSpec
- **Jobs**: Solid Queue (para actualización de facturas vencidas)
- **Docker**: Compatible

## 📋 Requisitos Previos

- Ruby 3.4.3
- Bundler 2.4.19
- Oracle Database XE (contenedor Docker)
- Docker y Docker Compose (para entorno completo)

## 🔧 Variables de Entorno

Crea un archivo `.env` en la raíz del servicio:

```env
# Base de datos Oracle
ORACLE_PASSWORD=developmentpass
RAILS_ENV=development

# Servicios externos
CLIENTS_SERVICE_URL=http://clients_service:3000
AUDIT_SERVICE_URL=http://audit_service:3002
```

## 🚀 Instalación

### Opción 1: Con Docker (Recomendado)

```bash
# Desde la raíz del proyecto principal
docker-compose up billing_service
```

### Opción 2: Local

```bash
# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create
rails db:migrate

# Iniciar servidor
rails server -p 3001
```

## 📡 API Endpoints

### Health Check
```
GET /api/v1/health_check
```

### Listar Facturas
```
GET /api/v1/facturas
```

**Parámetros opcionales:**
- `client_id`: Filtra por ID del cliente
- `invoice_number`: Filtra por número de factura
- `status`: Filtra por estado (`pending`, `paid`, `overdue`, `cancelled`)
- `fechaInicio`: Fecha inicio (formato: YYYY-MM-DD)
- `fechaFin`: Fecha fin (formato: YYYY-MM-DD)

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": "INV-20240101-0001",
      "client_id": 1,
      "issue_date": "2024-01-01",
      "due_date": "2024-01-31",
      "subtotal": "100.00",
      "tax": "19.00",
      "total": "119.00",
      "status": "pending",
      "notes": "Factura de servicios",
      "created_at": "2024-01-01T00:00:00.000Z",
      "client": {
        "id": 1,
        "name": "Juan Pérez",
        "email": "juan@example.com"
      }
    }
  ],
  "total_invoices": 1
}
```

### Obtener Factura
```
GET /api/v1/facturas/:id
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "invoice_number": "INV-20240101-0001",
    "client_id": 1,
    "issue_date": "2024-01-01",
    "due_date": "2024-01-31",
    "subtotal": "100.00",
    "tax": "19.00",
    "total": "119.00",
    "status": "pending",
    "notes": "Factura de servicios",
    "created_at": "2024-01-01T00:00:00.000Z",
    "client": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "identification": "123456789",
      "address": "Calle 123"
    }
  }
}
```

### Crear Factura
```
POST /api/v1/facturas
Content-Type: application/json
```

**Body:**
```json
{
  "invoice": {
    "client_id": 1,
    "issue_date": "2024-01-01",
    "due_date": "2024-01-31",
    "subtotal": 100.00,
    "tax": 19.00,
    "notes": "Factura de servicios"
  }
}
```

**Campos opcionales:**
- `invoice_number`: Se genera automáticamente si no se proporciona
- `status`: Por defecto es `pending`
- `tax`: Por defecto es 0.00

**Respuesta exitosa (201):**
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 1,
    "invoice_number": "INV-20240101-0001",
    "client_id": 1,
    "issue_date": "2024-01-01",
    "due_date": "2024-01-31",
    "subtotal": "100.00",
    "tax": "19.00",
    "total": "119.00",
    "status": "pending",
    "notes": "Factura de servicios",
    "created_at": "2024-01-01T00:00:00.000Z",
    "client": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com"
    }
  }
}
```

## 📝 Validaciones

### Campo `invoice_number`
- Único en el sistema
- Se genera automáticamente con formato: `INV-YYYYMMDD-XXXX`

### Campo `client_id`
- Obligatorio
- Debe existir en el servicio de clientes

### Campo `issue_date`
- Obligatorio
- No puede ser anterior a la fecha actual
- Por defecto es la fecha actual

### Campo `due_date`
- Opcional
- No puede ser anterior a la fecha actual

### Campo `subtotal`
- Obligatorio
- Debe ser >= 0

### Campo `tax`
- Opcional (por defecto 0.00)
- Debe ser >= 0

### Campo `total`
- Se calcula automáticamente: `subtotal + tax`

### Campo `status`
- Valores permitidos: `pending`, `paid`, `overdue`, `cancelled`
- Por defecto es `pending`
- Se actualiza automáticamente a `overdue` si pasa la fecha de vencimiento

## 🧪 Testing

```bash
# Ejecutar todos los tests
bundle exec rspec

# Ejecutar tests específicos
bundle exec rspec spec/models/invoice_spec.rb
bundle exec rspec spec/controllers/api/v1/invoices_controller_spec.rb
```

## 🔍 Ejemplos de Uso

### Crear una factura
```bash
curl -X POST http://localhost:3001/api/v1/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "client_id": 1,
      "issue_date": "2024-01-15",
      "due_date": "2024-02-15",
      "subtotal": 500.00,
      "tax": 95.00,
      "notes": "Servicios de consultoría"
    }
  }'
```

### Listar facturas de un cliente
```bash
curl "http://localhost:3001/api/v1/facturas?client_id=1"
```

### Filtrar por estado
```bash
curl "http://localhost:3001/api/v1/facturas?status=pending"
```

### Filtrar por rango de fechas
```bash
curl "http://localhost:3001/api/v1/facturas?fechaInicio=2024-01-01&fechaFin=2024-01-31"
```

### Buscar por número de factura
```bash
curl "http://localhost:3001/api/v1/facturas?invoice_number=INV-20240101-0001"
```

### Obtener factura específica
```bash
curl http://localhost:3001/api/v1/facturas/1
```

## 🔗 Integración con Otros Servicios

### Servicio de Clientes
- Valida que el cliente exista antes de crear una factura
- Obtiene información del cliente para incluirla en las respuestas

### Servicio de Auditoría
Registra automáticamente:
- Creación de facturas
- Lectura de facturas
- Errores en operaciones

## ⏰ Tareas Programadas

### Actualización de Facturas Vencidas
Se ejecuta periódicamente para actualizar el estado de facturas pendientes que han pasado su fecha de vencimiento.

```ruby
# Ejecutar manualmente
rails runner "Invoice.pending.each { |invoice| invoice.check_overdue_status }"
```

## 🐛 Manejo de Errores

### Factura no encontrada (404)
```json
{
  "success": false,
  "message": "Factura no encontrada"
}
```

### Cliente no encontrado (404)
```json
{
  "success": false,
  "message": "Cliente no encontrado"
}
```

### Error de validación (422)
```json
{
  "success": false,
  "message": "No se pudo crear la factura",
  "errors": [
    "Client id el cliente no existe en el servicio de clientes",
    "Issue date no puede ser anterior a la fecha actual"
  ]
}
```

### Formato de fecha inválido (400)
```json
{
  "success": false,
  "message": "Formato de fecha inválido. Use formato YYYY-MM-DD"
}
```

## 📊 Estructura del Proyecto

```
billing_service/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       └── invoices_controller.rb
│   ├── models/
│   │   └── invoice.rb
│   └── services/
│       ├── audit_service.rb
│       ├── clients_service.rb
│       └── tributary_authorities/
│           ├── dian_service.rb
│           └── ...
├── config/
│   ├── database.yml
│   └── routes.rb
├── db/
│   └── migrate/
├── spec/
└── Dockerfile
```

## 🔄 Scopes Disponibles

```ruby
# Facturas pendientes
Invoice.pending

# Facturas pagadas
Invoice.paid

# Facturas vencidas
Invoice.overdue

# Facturas de un cliente
Invoice.by_client(client_id)
```

## 💡 Características Adicionales

### Generación Automática de Número de Factura
El número se genera con el formato: `INV-YYYYMMDD-XXXX`
- `YYYYMMDD`: Fecha actual
- `XXXX`: Número secuencial del día (0001, 0002, etc.)

### Cálculo Automático de Total
El sistema calcula automáticamente: `total = subtotal + tax`

### Detección Automática de Facturas Vencidas
Las facturas pendientes se marcan como `overdue` automáticamente al consultarlas si han pasado su fecha de vencimiento.

## 🏷️ Versionado

**Versión actual:** v1
**Puerto por defecto:** 3001

## 📚 Documentación Adicional

Para información sobre integración con la DIAN (futura implementación), consulta el archivo `DIAN_FUTURE_IMPLEMENTATION.md`.

Para más información sobre la arquitectura completa del sistema, consulta el README principal del proyecto.
