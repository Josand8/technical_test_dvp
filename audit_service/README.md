# Servicio de Auditoría - API REST

Microservicio para la gestión de auditoría desarrollado con Ruby on Rails 7.1 y MongoDB usando Mongoid. Registra eventos de creación, consulta y errores de clientes y facturas de forma automática.

## 📋 Tabla de Contenidos

- [🛠 Requisitos](#-requisitos)
- [⚙️ Configuración](#️-configuración)
- [🗄️ Base de Datos](#️-base-de-datos)
- [🚀 Ejecución](#-ejecución)
- [📡 API Endpoints](#-api-endpoints)
- [💡 Ejemplos de Uso](#-ejemplos-de-uso)
- [🧪 Testing](#-testing)
- [📊 Modelo de Datos](#-modelo-de-datos)
- [🔗 Integración con Otros Servicios](#-integración-con-otros-servicios)
- [🔧 Comandos Útiles](#-comandos-útiles)
- [📝 Notas Adicionales](#-notas-adicionales)
- [🐛 Solución de Problemas](#-solución-de-problemas)

## 🛠 Requisitos

- Ruby 3.4.3 o superior
- Rails 7.1.6
- MongoDB 4.4 o superior

## ⚙️ Configuración

### 1. Instalar dependencias

```bash
bundle install
```

### 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto:

```env
# MongoDB Configuration
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=audit_service_development
MONGODB_USERNAME=
MONGODB_PASSWORD=
```

**Nota:** Para producción, configurar `MONGODB_USERNAME` y `MONGODB_PASSWORD` con las credenciales apropiadas.

## 🗄️ Base de Datos

### Iniciar MongoDB

```bash
# En macOS con Homebrew
brew services start mongodb-community

# O ejecutar MongoDB directamente
mongod --config /usr/local/etc/mongod.conf
```

### Verificar conexión

El servicio se conectará automáticamente a MongoDB al iniciar. La base de datos se creará automáticamente cuando se inserte el primer documento.

### Estructura de colecciones

MongoDB es una base de datos NoSQL orientada a documentos. Las colecciones se crean automáticamente cuando se inserta el primer documento.

**Nota:** Este servicio utiliza Mongoid como ODM (Object-Document Mapper) para MongoDB, que es el estándar para Rails.

## 🚀 Ejecución

### Modo desarrollo

```bash
# El servicio de auditoría corre en el puerto 3002 para no conflictuar con otros servicios
bin/rails server -p 3002
```

El servicio estará disponible en: `http://localhost:3002`

### Verificar el servicio

```bash
curl http://localhost:3002/api/v1/health_check
```

Respuesta esperada:
```json
{
  "status": "Audit Service is running"
}
```

## 📡 API Endpoints

### Base URL
```
http://localhost:3002/api/v1
```

### 1. Health Check

**GET** `/api/v1/health_check`

Verifica el estado del servicio.

**Respuesta:**
```json
{
  "status": "Audit Service is running"
}
```

---

### 2. Listar Eventos de Auditoría

**GET** `/api/v1/auditoria`

Lista todos los eventos de auditoría con filtros opcionales (últimos 100).

**Parámetros de consulta opcionales:**
- `resource_type` - Tipo de recurso (`client` o `invoice`)
- `resource_id` - ID del recurso
- `status` - Estado del evento (`success` o `failed`)
- `start_date` - Fecha de inicio (ISO 8601)
- `end_date` - Fecha de fin (ISO 8601)

**Ejemplos:**
```bash
# Todos los eventos
curl http://localhost:3002/api/v1/auditoria

# Solo eventos de clientes
curl "http://localhost:3002/api/v1/auditoria?resource_type=client"

# Solo eventos con errores
curl "http://localhost:3002/api/v1/auditoria?status=failed"

# Eventos de un recurso específico
curl "http://localhost:3002/api/v1/auditoria?resource_id=1&resource_type=client"
```

**Respuesta:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "6915d583e62aecae4443906b",
      "resource_type": "client",
      "resource_id": "1",
      "action": "create",
      "changes_made": {
        "name": "Juan Pérez",
        "email": "juan@test.com"
      },
      "status": "success",
      "error_message": null,
      "created_at": "2025-11-13T12:56:35.843Z",
      "updated_at": "2025-11-13T12:56:35.843Z"
    }
  ],
  "total_audit_logs": 1
}
```

---

### 3. Consultar Eventos por Recurso

**GET** `/api/v1/auditoria/:resource_id`

Consulta todos los eventos de auditoría relacionados con un recurso específico (cliente o factura).

**Parámetros de ruta:**
- `resource_id` - ID del recurso a consultar

**Parámetros de consulta opcionales:**
- `resource_type` - Filtrar por tipo (`client` o `invoice`)

**Ejemplos:**
```bash
# Eventos de un cliente específico
curl "http://localhost:3002/api/v1/auditoria/1?resource_type=client"

# Eventos de una factura específica
curl "http://localhost:3002/api/v1/auditoria/5?resource_type=invoice"

# Eventos de cualquier recurso con ID 1 (cliente o factura)
curl "http://localhost:3002/api/v1/auditoria/1"
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "6915d6cde62aecae44439076",
      "resource_type": "client",
      "resource_id": "1",
      "action": "read",
      "changes_made": {},
      "status": "success",
      "error_message": null,
      "created_at": "2025-11-13T13:02:05.650Z",
      "updated_at": "2025-11-13T13:02:05.650Z"
    },
    {
      "_id": "6915d583e62aecae4443906b",
      "resource_type": "client",
      "resource_id": "1",
      "action": "create",
      "changes_made": {
        "name": "Juan Pérez",
        "email": "juan@test.com",
        "identification": "12345678",
        "address": "Calle Principal 123"
      },
      "status": "success",
      "error_message": null,
      "created_at": "2025-11-13T12:56:35.843Z",
      "updated_at": "2025-11-13T12:56:35.843Z"
    }
  ],
  "total_audit_logs": 2
}
```

**Respuesta cuando no hay eventos:**
```json
{
  "success": false,
  "message": "No se encontraron logs para el recurso con id 99999"
}
```

---

### 4. Crear Evento de Auditoría (Uso Interno)

**POST** `/api/v1/auditoria`

Crea un nuevo evento de auditoría. Este endpoint es utilizado internamente por los servicios de Clients y Billing.

**Body:**
```json
{
  "audit_log": {
    "resource_type": "client",
    "resource_id": "1",
    "action": "create",
    "changes_made": {
      "name": "Juan Pérez",
      "email": "juan@test.com"
    },
    "status": "success",
    "error_message": null
  }
}
```

**Parámetros:**
- `resource_type` - Tipo de recurso: `client` o `invoice` (requerido)
- `resource_id` - ID del recurso (requerido)
- `action` - Acción realizada: `create`, `read`, `update`, `delete`, `error` (requerido)
- `changes_made` - Hash con los cambios realizados (opcional)
- `status` - Estado: `success` o `failed` (requerido)
- `error_message` - Mensaje de error si `status` es `failed` (opcional)

**Respuesta exitosa:**
```json
{
  "success": true,
  "message": "Log creado exitosamente",
  "data": {
    "_id": "6915d583e62aecae4443906b",
    "resource_type": "client",
    "resource_id": "1",
    "action": "create",
    "changes_made": {
      "name": "Juan Pérez"
    },
    "status": "success",
    "error_message": null,
    "created_at": "2025-11-13T12:56:35.843Z",
    "updated_at": "2025-11-13T12:56:35.843Z"
  }
}
```

---

## 💡 Ejemplos de Uso

### Caso 1: Rastrear actividad de un cliente

```bash
# 1. Crear un cliente en clients_service (genera evento automáticamente)
curl -X POST http://localhost:3000/api/v1/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "María López",
      "email": "maria@empresa.com"
    }
  }'

# 2. Consultar el cliente (genera evento de lectura)
curl http://localhost:3000/api/v1/clients/1

# 3. Ver todos los eventos del cliente
curl "http://localhost:3002/api/v1/auditoria/1?resource_type=client"
```

### Caso 2: Auditar errores del sistema

```bash
# Ver todos los eventos con errores
curl "http://localhost:3002/api/v1/auditoria?status=failed"
```

### Caso 3: Historial completo de una factura

```bash
# Ver todos los eventos de la factura #5
curl "http://localhost:3002/api/v1/auditoria/5?resource_type=invoice"
```

---

## 🧪 Testing

### Ejecutar todos los tests

```bash
# Con RSpec
bundle exec rspec

# Tests específicos
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
```

### Cobertura de Tests

El proyecto incluye tests para:
- ✅ Modelo `AuditLog` (validaciones, campos, índices)
- ✅ Controlador `AuditLogController` (todos los endpoints)
- ✅ Factories con FactoryBot
- ✅ Casos de error y validación

## 📊 Modelo de Datos

### AuditLog

El modelo principal del servicio:

```ruby
class AuditLog < ApplicationDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  field :resource_type, type: String         # 'client' o 'invoice'
  field :resource_id, type: String           # ID del recurso
  field :action, type: String                # 'create', 'read', 'update', 'delete', 'error'
  field :changes_made, type: Hash, default: {} # Cambios realizados
  field :status, type: String                # 'success' o 'failed'
  field :error_message, type: String         # Mensaje de error (opcional)
  field :created_at, type: DateTime          # Timestamp automático

  # Validaciones
  validates :resource_type, presence: true, inclusion: { in: %w[client invoice] }
  validates :resource_id, presence: true
  validates :action, presence: true, inclusion: { in: %w[create read update delete error] }
  validates :status, presence: true, inclusion: { in: %w[success failed] }

  # Índices para optimización de consultas
  index({ resource_type: 1, resource_id: 1 })  # Búsqueda por tipo y ID
  index({ created_at: -1 })                    # Ordenamiento por fecha
  index({ status: 1 })                         # Filtrado por estado
end
```

### Campos del Modelo

| Campo | Tipo | Descripción | Valores Permitidos |
|-------|------|-------------|-------------------|
| `resource_type` | String | Tipo de recurso auditado | `client`, `invoice` |
| `resource_id` | String | ID del recurso | Cualquier string |
| `action` | String | Acción realizada | `create`, `read`, `update`, `delete`, `error` |
| `changes_made` | Hash | Datos modificados | Hash con los cambios |
| `status` | String | Estado del evento | `success`, `failed` |
| `error_message` | String | Mensaje de error | Cualquier string (opcional) |
| `created_at` | DateTime | Fecha de creación | Timestamp automático |
| `updated_at` | DateTime | Fecha de actualización | Timestamp automático |

### Índices MongoDB

Los índices mejoran el rendimiento de las consultas:

```javascript
// Buscar eventos por tipo y ID de recurso
db.audit_logs.find({ resource_type: "client", resource_id: "1" })

// Ordenar eventos por fecha (descendente)
db.audit_logs.find().sort({ created_at: -1 })

// Filtrar eventos por estado
db.audit_logs.find({ status: "failed" })
```

---

## 🔗 Integración con Otros Servicios

### Arquitectura del Sistema

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Clients        │         │  Billing        │         │  Audit          │
│  Service        │────────▶│  Service        │────────▶│  Service        │
│  (Port 3000)    │         │  (Port 3001)    │         │  (Port 3002)    │
│  PostgreSQL     │         │  PostgreSQL     │         │  MongoDB        │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

### Eventos Registrados Automáticamente

#### Desde Clients Service:
- ✅ Creación exitosa de cliente
- ✅ Consulta de cliente específico
- ✅ Error al crear cliente (validación fallida)
- ✅ Error al consultar cliente (no encontrado)

#### Desde Billing Service:
- ✅ Creación exitosa de factura
- ✅ Consulta de factura específica
- ✅ Error al crear factura (validación fallida)
- ✅ Error al consultar factura (no encontrada)

### Configuración en Otros Servicios

Los servicios de Clients y Billing se comunican con el Audit Service mediante HTTP. Configurar en sus archivos `.env`:

```env
AUDIT_SERVICE_URL=http://localhost:3002
```

### Clase AuditService (en clients_service y billing_service)

```ruby
class AuditService
  AUDIT_SERVICE_URL = ENV.fetch('AUDIT_SERVICE_URL', 'http://localhost:3002')

  def self.log_create(resource_type, resource_id, changes_made = {})
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: 'create',
      changes_made: changes_made,
      status: 'success'
    )
  end

  def self.log_read(resource_type, resource_id)
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: 'read',
      status: 'success'
    )
  end

  def self.log_error(resource_type, resource_id, error_message, action = 'error')
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: action,
      status: 'failed',
      error_message: error_message
    )
  end
end
```

---

## 🔧 Comandos Útiles

### Gestión de Base de Datos

```bash
# Limpiar todos los eventos de auditoría
bin/rails audit:clear

# Ver estadísticas de auditoría
bin/rails audit:stats

# Reiniciar completamente la base de datos
bin/rails audit:reset

# O usar el script de shell
./reset_mongo.sh
```

### Desarrollo

```bash
# Ver rutas disponibles
rails routes

# Consola interactiva de Rails
rails console

# Consola de MongoDB
mongosh audit_service_development

# Verificar sintaxis (Rubocop)
rubocop

# Análisis de seguridad
brakeman

# Ejecutar tests
bundle exec rspec
```

### Consultas MongoDB

```bash
# Conectar a la base de datos
mongosh audit_service_development

# Ver colecciones
show collections

# Contar documentos
db.audit_logs.countDocuments()

# Ver últimos 5 eventos
db.audit_logs.find().sort({created_at: -1}).limit(5)

# Ver eventos de un cliente específico
db.audit_logs.find({resource_type: "client", resource_id: "1"})

# Ver eventos con errores
db.audit_logs.find({status: "failed"})

# Limpiar todos los eventos
db.audit_logs.deleteMany({})
```

## 📝 Notas Adicionales

### Características del Servicio

- ✅ **Base de datos NoSQL**: MongoDB para almacenamiento flexible y escalable
- ✅ **Arquitectura de Microservicios**: Servicio independiente y desacoplado
- ✅ **API REST**: Endpoints simples y bien documentados
- ✅ **Registro Automático**: Integración transparente con otros servicios
- ✅ **Resiliencia**: Si el servicio falla, los otros servicios continúan funcionando
- ✅ **Trazabilidad**: Historial completo de operaciones y errores
- ✅ **Testing**: Suite completa de tests con RSpec

### Tecnologías Utilizadas

- **Ruby**: 3.4.3
- **Rails**: 7.1.6
- **MongoDB**: 4.4+
- **Mongoid**: 8.1 (ODM)
- **RSpec**: Testing framework
- **FactoryBot**: Fixtures de prueba

### Ventajas de MongoDB para Auditoría

1. **Esquema Flexible**: El campo `changes_made` puede almacenar cualquier estructura
2. **Alta Performance**: Índices optimizados para búsquedas rápidas
3. **Escalabilidad**: Fácil de escalar horizontalmente
4. **Documentos JSON**: Formato natural para APIs REST

### Puerto por Defecto

El servicio corre en el **puerto 3002** para evitar conflictos:
- Puerto 3000: Clients Service
- Puerto 3001: Billing Service
- Puerto 3002: Audit Service

## 🐛 Solución de Problemas

### Error de conexión a MongoDB

Si tienes problemas de conexión a MongoDB, verifica:

1. Que MongoDB esté corriendo:
```bash
# En macOS con Homebrew
brew services start mongodb-community

# Verificar estado
brew services list

# O verificar el proceso
ps aux | grep mongod
```

2. Las credenciales en `.env` sean correctas
3. El puerto 27017 esté disponible
4. Que el usuario de MongoDB tenga permisos

### El servicio no registra eventos

Si los eventos no se están registrando desde clients_service o billing_service:

1. **Verifica que el Audit Service esté corriendo:**
```bash
curl http://localhost:3002/api/v1/health_check
```

2. **Verifica la variable de entorno en los otros servicios:**
```bash
# En clients_service/.env y billing_service/.env
AUDIT_SERVICE_URL=http://localhost:3002
```

3. **Revisa los logs del servicio que hace la llamada:**
```bash
# En billing_service o clients_service
tail -f log/development.log | grep Audit
```

4. **Prueba crear un evento manualmente:**
```bash
curl -X POST http://localhost:3002/api/v1/auditoria \
  -H "Content-Type: application/json" \
  -d '{
    "audit_log": {
      "resource_type": "client",
      "resource_id": "test",
      "action": "create",
      "status": "success"
    }
  }'
```

### Campo changes_made aparece como null

Asegúrate de que:
1. El Audit Service esté actualizado con el fix de Strong Parameters
2. Has reiniciado el servidor después de los cambios
3. El campo se está enviando correctamente desde el otro servicio

### Limpiar base de datos de desarrollo

```bash
# Opción 1: Usar la tarea de Rake
cd audit_service
bin/rails audit:clear

# Opción 2: Usar MongoDB directamente
mongosh audit_service_development --eval "db.audit_logs.deleteMany({})"

# Opción 3: Eliminar la base de datos completa
mongosh audit_service_development --eval "db.dropDatabase()"
```

### Problemas con Mongoid

```bash
# Verificar la configuración
rails console
> Mongoid.clients
> Mongoid.default_client.database.name

# Verificar que el modelo funcione
> AuditLog.count
> AuditLog.create(resource_type: 'client', resource_id: '1', action: 'create', status: 'success')
```

### Puerto en uso

Si el puerto 3002 ya está en uso:

```bash
# Encontrar el proceso
lsof -i :3002

# Matar el proceso
kill -9 <PID>

# O usar otro puerto
bin/rails server -p 3003
```

---

## 📚 Documentación Adicional

- [README_IMPLEMENTACION.md](./README_IMPLEMENTACION.md) - Guía completa de implementación
- [EJEMPLOS_API.md](./EJEMPLOS_API.md) - Ejemplos detallados de uso de la API
- [../ARQUITECTURA_AUDIT.md](../ARQUITECTURA_AUDIT.md) - Diagrama de arquitectura del sistema

---

## 🤝 Contribución

Para contribuir al proyecto:

1. Asegúrate de que todos los tests pasen: `bundle exec rspec`
2. Verifica el estilo de código: `rubocop`
3. Ejecuta el análisis de seguridad: `brakeman`

---

## 📄 Licencia

Este proyecto es parte de una prueba técnica para desarrollador Full Stack.

---

**Autor**: Desarrollado como parte del sistema de gestión de clientes y facturación  
**Fecha**: Noviembre 2025
