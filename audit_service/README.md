# 🔍 Servicio de Auditoría

Microservicio centralizado para registro y consulta de logs de auditoría del sistema. Utiliza MongoDB para almacenar eventos de todos los servicios.

## 🛠️ Tecnologías

- **Ruby**: 3.4.3
- **Rails**: 7.1.0
- **Base de datos**: MongoDB con Mongoid (~> 8.1)
- **Testing**: RSpec
- **Docker**: Compatible

## 📋 Requisitos Previos

- Ruby 3.4.3
- Bundler 2.4.19
- MongoDB 4.0+
- Docker y Docker Compose (para entorno completo)

## 🔧 Variables de Entorno

Crea un archivo `.env` en la raíz del servicio:

```env
# Base de datos MongoDB
MONGODB_HOST=mongodb
MONGODB_PORT=27017
MONGODB_USERNAME=
MONGODB_PASSWORD=
RAILS_ENV=development
```

## 🚀 Instalación

### Opción 1: Con Docker (Recomendado)

```bash
# Desde la raíz del proyecto principal
docker-compose up audit_service mongodb
```

### Opción 2: Local

```bash
# Instalar dependencias
bundle install

# Iniciar MongoDB (si no está corriendo)
mongod --dbpath /path/to/data

# Iniciar servidor
rails server -p 3002
```

## 📡 API Endpoints

### Health Check
```
GET /api/v1/health_check
```

### Listar Logs de Auditoría
```
GET /api/v1/auditoria
```

**Parámetros opcionales:**
- `resource_type`: Filtra por tipo de recurso (`client`, `invoice`)
- `resource_id`: Filtra por ID del recurso
- `status`: Filtra por estado (`success`, `failed`)
- `start_date`: Fecha inicio (formato ISO 8601)
- `end_date`: Fecha fin (formato ISO 8601)

**Nota:** Retorna máximo 100 registros, ordenados por fecha descendente.

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "_id": {
        "$oid": "507f1f77bcf86cd799439011"
      },
      "resource_type": "client",
      "resource_id": "1",
      "action": "create",
      "changes_made": {
        "name": "Juan Pérez",
        "email": "juan@example.com"
      },
      "status": "success",
      "error_message": null,
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "total_audit_logs": 1
}
```

### Obtener Logs de un Recurso
```
GET /api/v1/auditoria/:resource_id
```

**Parámetros opcionales:**
- `resource_type`: Filtra por tipo de recurso

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "_id": {
        "$oid": "507f1f77bcf86cd799439011"
      },
      "resource_type": "client",
      "resource_id": "1",
      "action": "create",
      "changes_made": {
        "name": "Juan Pérez"
      },
      "status": "success",
      "error_message": null,
      "created_at": "2024-01-01T00:00:00.000Z"
    },
    {
      "_id": {
        "$oid": "507f1f77bcf86cd799439012"
      },
      "resource_type": "client",
      "resource_id": "1",
      "action": "read",
      "changes_made": {},
      "status": "success",
      "error_message": null,
      "created_at": "2024-01-01T01:00:00.000Z"
    }
  ],
  "total_audit_logs": 2
}
```

### Crear Log de Auditoría
```
POST /api/v1/auditoria
Content-Type: application/json
```

**Body:**
```json
{
  "audit_log": {
    "resource_type": "client",
    "resource_id": "1",
    "action": "create",
    "status": "success",
    "changes_made": {
      "name": "Juan Pérez",
      "email": "juan@example.com"
    }
  }
}
```

**Respuesta exitosa (201):**
```json
{
  "success": true,
  "message": "Log creado exitosamente",
  "data": {
    "_id": {
      "$oid": "507f1f77bcf86cd799439011"
    },
    "resource_type": "client",
    "resource_id": "1",
    "action": "create",
    "changes_made": {
      "name": "Juan Pérez",
      "email": "juan@example.com"
    },
    "status": "success",
    "error_message": null,
    "created_at": "2024-01-01T00:00:00.000Z"
  }
}
```

## 📝 Campos del Modelo AuditLog

### `resource_type` (String)
- **Obligatorio**
- Valores permitidos: `client`, `invoice`
- Indica el tipo de recurso auditado

### `resource_id` (String)
- **Obligatorio**
- ID del recurso en su servicio original

### `action` (String)
- **Obligatorio**
- Valores permitidos: `create`, `read`, `update`, `delete`, `error`
- Indica la acción realizada

### `status` (String)
- **Obligatorio**
- Valores permitidos: `success`, `failed`
- Indica si la operación fue exitosa

### `changes_made` (Hash)
- Opcional (por defecto `{}`)
- Almacena los cambios realizados o datos relevantes

### `error_message` (String)
- Opcional
- Mensaje de error si `status` es `failed`

### `created_at` (DateTime)
- Se establece automáticamente

## 🧪 Testing

```bash
# Ejecutar todos los tests
bundle exec rspec

# Ejecutar tests específicos
bundle exec rspec spec/models/audit_log_spec.rb
bundle exec rspec spec/controllers/api/v1/audit_log_controller_spec.rb
```

## 🔍 Ejemplos de Uso

### Registrar creación exitosa de un cliente
```bash
curl -X POST http://localhost:3002/api/v1/auditoria \
  -H "Content-Type: application/json" \
  -d '{
    "audit_log": {
      "resource_type": "client",
      "resource_id": "123",
      "action": "create",
      "status": "success",
      "changes_made": {
        "name": "María García",
        "email": "maria@example.com"
      }
    }
  }'
```

### Registrar error en operación
```bash
curl -X POST http://localhost:3002/api/v1/auditoria \
  -H "Content-Type: application/json" \
  -d '{
    "audit_log": {
      "resource_type": "invoice",
      "resource_id": "unknown",
      "action": "error",
      "status": "failed",
      "error_message": "Cliente no existe"
    }
  }'
```

### Consultar todos los logs
```bash
curl http://localhost:3002/api/v1/auditoria
```

### Filtrar por tipo de recurso
```bash
curl "http://localhost:3002/api/v1/auditoria?resource_type=client"
```

### Filtrar por estado
```bash
curl "http://localhost:3002/api/v1/auditoria?status=failed"
```

### Filtrar por rango de fechas
```bash
curl "http://localhost:3002/api/v1/auditoria?start_date=2024-01-01T00:00:00Z&end_date=2024-01-31T23:59:59Z"
```

### Obtener logs de un recurso específico
```bash
curl "http://localhost:3002/api/v1/auditoria/123"
```

### Obtener logs de un recurso con filtro por tipo
```bash
curl "http://localhost:3002/api/v1/auditoria/123?resource_type=client"
```

## 🔗 Integración con Otros Servicios

Este servicio es consumido por:
- **Servicio de Clientes**: Para registrar operaciones CRUD
- **Servicio de Facturas**: Para registrar operaciones CRUD

Los servicios utilizan el helper `AuditService` para comunicarse con este microservicio.

## 🐛 Manejo de Errores

### Recurso no encontrado (404)
```json
{
  "success": false,
  "message": "No se encontraron logs para el recurso client con id 123"
}
```

### Error de validación (422)
```json
{
  "success": false,
  "message": "No se pudo crear el log",
  "errors": [
    "Resource type no está incluido en la lista",
    "Action no está incluido en la lista"
  ]
}
```

## 📊 Estructura del Proyecto

```
audit_service/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       └── audit_log_controller.rb
│   └── models/
│       └── audit_log.rb
├── config/
│   ├── mongoid.yml
│   └── routes.rb
├── spec/
│   ├── controllers/
│   ├── factories/
│   └── models/
└── Dockerfile
```

## 🗂️ Índices de MongoDB

Para optimizar las consultas, se crean los siguientes índices:

```ruby
# Índices compuestos
index({ resource_type: 1, resource_id: 1 })
index({ resource_type: 1, status: 1, created_at: -1 })
index({ status: 1, created_at: -1 })

# Índices simples
index({ resource_id: 1 })
index({ created_at: -1 })
index({ status: 1 })
```

## 🔄 Tipos de Acciones Registradas

### `create`
Registra la creación de un nuevo recurso con sus datos iniciales.

### `read`
Registra consultas de recursos (útil para auditoría de accesos).

### `update`
Registra modificaciones a recursos existentes.

### `delete`
Registra eliminación de recursos.

### `error`
Registra errores en operaciones, con mensaje descriptivo.

## 💾 Persistencia y Rendimiento

- **Base de datos**: MongoDB (esquema flexible para diferentes tipos de logs)
- **Límite por consulta**: 100 registros
- **Ordenamiento**: Por defecto por fecha descendente (más recientes primero)
- **Índices**: Optimizados para consultas frecuentes

## 📈 Casos de Uso Comunes

### Auditoría de accesos a datos sensibles
```bash
curl "http://localhost:3002/api/v1/auditoria?action=read&resource_type=client"
```

### Investigación de errores
```bash
curl "http://localhost:3002/api/v1/auditoria?status=failed"
```

### Trazabilidad de cambios en un recurso
```bash
curl "http://localhost:3002/api/v1/auditoria/123?resource_type=invoice"
```

### Análisis de actividad en un periodo
```bash
curl "http://localhost:3002/api/v1/auditoria?start_date=2024-01-01T00:00:00Z&end_date=2024-01-31T23:59:59Z"
```

## 🏷️ Versionado

**Versión actual:** v1
**Puerto por defecto:** 3002

## ⚠️ Consideraciones Importantes

1. **Límite de registros**: Las consultas retornan máximo 100 registros por razones de rendimiento
2. **Formato de fechas**: Use formato ISO 8601 para filtros de fecha
3. **No hay eliminación**: Los logs son inmutables, no se pueden eliminar o modificar
4. **Asincrono**: Los servicios registran logs de forma asíncrona para no afectar el rendimiento

## 📚 Documentación Adicional

Para más información sobre la arquitectura completa del sistema, consulta el README principal del proyecto.
