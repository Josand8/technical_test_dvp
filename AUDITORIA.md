# Sistema de Auditoría con Message Broker

## Descripción General

Se ha implementado un sistema completo de auditoría distribuida que utiliza **RabbitMQ** como message broker para registrar todas las operaciones realizadas en los servicios de `billing_service` y `clients_service`. Los logs de auditoría son persistidos de forma asíncrona en el `audit_service` utilizando MongoDB.

## Arquitectura

```
┌─────────────────┐         ┌─────────────────┐
│ Clients Service │         │ Billing Service │
│   (PostgreSQL)  │         │   (PostgreSQL)  │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │ Publica eventos           │ Publica eventos
         │ de auditoría              │ de auditoría
         │                           │
         └───────────┬───────────────┘
                     ↓
            ┌────────────────┐
            │   RabbitMQ     │
            │ (Message Broker)│
            └────────┬────────┘
                     │
                     │ Consume eventos
                     ↓
            ┌────────────────┐
            │ Audit Service  │
            │   (MongoDB)    │
            └────────────────┘
```

## Componentes Implementados

### 1. **RabbitMQ como Message Broker**

- **Exchange**: `audit_events` (tipo: topic, durable: true)
- **Queue**: `audit_logs` (durable: true)
- **Routing Keys**:
  - `audit.client.create` - Creación de clientes
  - `audit.client.update` - Actualización de clientes
  - `audit.client.delete` - Eliminación de clientes
  - `audit.client.read` - Lectura de clientes
  - `audit.invoice.create` - Creación de facturas
  - `audit.invoice.update` - Actualización de facturas
  - `audit.invoice.delete` - Eliminación de facturas
  - `audit.invoice.read` - Lectura de facturas
  - `audit.*.error` - Errores en operaciones

### 2. **Servicios de Publicación** (Billing & Clients)

#### AuditPublisherService

Servicio responsable de publicar eventos de auditoría a RabbitMQ:

```ruby
AuditPublisherService.publish(
  resource_type: 'client',
  resource_id: '123',
  action: 'create',
  changes_made: { name: 'John Doe', email: 'john@example.com' },
  status: 'success'
)
```

Métodos auxiliares:
- `publish_create(resource)` - Auditar creación
- `publish_update(resource, changes)` - Auditar actualización
- `publish_delete(resource)` - Auditar eliminación
- `publish_error(...)` - Auditar errores

### 3. **Concern Auditable**

Módulo que se incluye en los modelos para auditoría automática:

```ruby
class Invoice < ApplicationRecord
  include Auditable
  # ...
end
```

El concern registra automáticamente:
- `after_create` → Publica evento de creación
- `after_update` → Publica evento de actualización (solo cambios relevantes)
- `after_destroy` → Publica evento de eliminación
- `after_rollback` → Publica evento de error

### 4. **Consumer en Audit Service**

#### AuditConsumerJob

Job que consume mensajes de RabbitMQ y persiste los logs en MongoDB:

```ruby
# Ejecutar el consumer
bundle exec rake audit:consumer
```

Características:
- Acknowledgment manual (ack/nack)
- Reintento automático en caso de error
- Reconexión automática a RabbitMQ
- Logging detallado de operaciones

### 5. **Modelo AuditLog**

Modelo en MongoDB que almacena los logs de auditoría:

```ruby
{
  resource_type: 'client',      # Tipo de recurso (client, invoice)
  resource_id: '123',            # ID del recurso
  action: 'create',              # Acción (create, read, update, delete, error)
  changes_made: { ... },         # Hash con los cambios realizados
  status: 'success',             # Estado (success, failed)
  error_message: nil,            # Mensaje de error (si aplica)
  created_at: DateTime
}
```

Validaciones:
- `resource_type`: debe ser 'client' o 'invoice'
- `action`: debe ser 'create', 'read', 'update', 'delete' o 'error'
- `status`: debe ser 'success' o 'failed'

Índices:
- `resource_type + resource_id`
- `created_at` (descendente)
- `status`

## Configuración

### Paso 1: Variables de Entorno

Crear archivos `.env` en cada servicio:

#### audit_service/.env
```bash
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/

MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=audit_service_development
```

#### billing_service/.env
```bash
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/

CLIENTS_SERVICE_URL=http://localhost:3001
```

#### clients_service/.env
```bash
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/
```

### Paso 2: Instalar Dependencias

En cada servicio:

```bash
cd audit_service
bundle install

cd ../billing_service
bundle install

cd ../clients_service
bundle install
```

### Paso 3: Iniciar RabbitMQ y Bases de Datos

Usando Docker Compose:

```bash
docker-compose -f docker-compose.rabbitmq.yml up -d
```

Esto iniciará:
- RabbitMQ en puerto 5672 (Management UI en http://localhost:15672)
- MongoDB en puerto 27017
- PostgreSQL en puerto 5432

### Paso 4: Configurar las Bases de Datos

```bash
# Billing Service
cd billing_service
rails db:create
rails db:migrate

# Clients Service
cd ../clients_service
rails db:create
rails db:migrate
```

### Paso 5: Iniciar los Servicios

En terminales separadas:

```bash
# Terminal 1: Audit Service
cd audit_service
rails server -p 3000

# Terminal 2: Audit Consumer
cd audit_service
bundle exec rake audit:consumer

# Terminal 3: Clients Service
cd clients_service
rails server -p 3001

# Terminal 4: Billing Service
cd billing_service
rails server -p 3002
```

## Flujo de Auditoría

### Ejemplo: Crear un Cliente

1. **Cliente hace POST** a `/api/v1/clients`
2. **ClientsController** crea el cliente
3. **Modelo Client** (con concern `Auditable`) dispara `after_create`
4. **AuditPublisherService** publica mensaje a RabbitMQ:
   ```json
   {
     "resource_type": "client",
     "resource_id": "123",
     "action": "create",
     "changes_made": {
       "name": "John Doe",
       "email": "john@example.com",
       "identification": "12345678"
     },
     "status": "success",
     "timestamp": "2025-11-13T10:30:00Z"
   }
   ```
5. **AuditConsumerJob** consume el mensaje de RabbitMQ
6. **AuditLog** se crea en MongoDB
7. Si hay error, el mensaje se reencola automáticamente

### Ejemplo: Actualizar una Factura

1. **Cliente hace PUT** a `/api/v1/invoices/:id`
2. **InvoicesController** actualiza la factura
3. **Modelo Invoice** dispara `after_update`
4. **Concern Auditable** filtra solo cambios relevantes (excluye `updated_at`, `created_at`)
5. **AuditPublisherService** publica evento con los cambios
6. **AuditConsumerJob** procesa y persiste el log

### Ejemplo: Consultar un Cliente

1. **Cliente hace GET** a `/api/v1/clients/:id`
2. **ClientsController** retorna el cliente
3. **after_action :audit_show** se ejecuta
4. **AuditPublisherService** publica evento de lectura
5. **AuditConsumerJob** registra la consulta en MongoDB

## API de Consulta de Logs

### GET /api/v1/auditoria

Consultar logs de auditoría con filtros:

```bash
# Todos los logs
GET http://localhost:3000/api/v1/auditoria

# Filtrar por tipo de recurso
GET http://localhost:3000/api/v1/auditoria?resource_type=client

# Filtrar por ID de recurso
GET http://localhost:3000/api/v1/auditoria?resource_id=123

# Filtrar por estado
GET http://localhost:3000/api/v1/auditoria?status=success

# Filtrar por rango de fechas
GET http://localhost:3000/api/v1/auditoria?start_date=2025-11-01&end_date=2025-11-30
```

Respuesta:
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "resource_type": "client",
      "resource_id": "123",
      "action": "create",
      "changes_made": { ... },
      "status": "success",
      "error_message": null,
      "created_at": "2025-11-13T10:30:00Z"
    }
  ],
  "total_audit_logs": 1
}
```

### GET /api/v1/auditoria/:resource_id

Consultar todos los logs de un recurso específico:

```bash
GET http://localhost:3000/api/v1/auditoria/123
```

## Monitoreo

### RabbitMQ Management UI

Acceder a http://localhost:15672
- Usuario: `guest`
- Contraseña: `guest`

Desde aquí puedes:
- Ver mensajes en la cola
- Monitorear el throughput
- Ver conexiones activas
- Estadísticas de exchanges y queues

### Logs de Aplicación

```bash
# Ver logs del consumer
tail -f audit_service/log/development.log

# Ver logs de publicación
tail -f billing_service/log/development.log
tail -f clients_service/log/development.log
```

## Características Adicionales

### 1. **Tolerancia a Fallos**

- Si RabbitMQ no está disponible, los eventos no se publican pero la operación continúa
- El consumer se reconecta automáticamente si pierde la conexión
- Los mensajes son persistentes (sobreviven reinicios de RabbitMQ)
- Acknowledgment manual para garantizar procesamiento

### 2. **No Intrusivo en Tests**

Por defecto, la auditoría no se ejecuta en tests:

```ruby
# Para habilitar auditoría en tests
ENV['AUDIT_IN_TEST'] = 'true'
```

### 3. **Filtrado Inteligente**

Solo se auditan cambios relevantes:
- Excluye `updated_at`, `created_at`
- No publica si no hay cambios
- Manejo especial de errores

### 4. **Logging Detallado**

Cada operación se registra en los logs:
```
Published audit event: audit.client.create for client#123
Processing audit event: audit.client.create
Audit log saved successfully: 507f1f77bcf86cd799439011
```

## Troubleshooting

### RabbitMQ no se conecta

```bash
# Verificar que RabbitMQ esté corriendo
docker ps | grep rabbitmq

# Ver logs de RabbitMQ
docker logs technical_test_rabbitmq

# Reiniciar RabbitMQ
docker-compose -f docker-compose.rabbitmq.yml restart rabbitmq
```

### Consumer no procesa mensajes

```bash
# Verificar que el consumer esté corriendo
ps aux | grep audit:consumer

# Ver cola de mensajes
# Acceder a http://localhost:15672 y revisar la cola 'audit_logs'

# Reiniciar consumer
# Ctrl+C en la terminal del consumer
bundle exec rake audit:consumer
```

### Mensajes no se publican

```bash
# Verificar configuración de RabbitMQ
echo $RABBITMQ_HOST

# Ver logs de la aplicación
tail -f log/development.log | grep "audit"

# Verificar conectividad
telnet localhost 5672
```

## Ventajas del Sistema

1. **Desacoplamiento**: Los servicios no dependen del servicio de auditoría
2. **Asincronía**: No impacta el rendimiento de las operaciones principales
3. **Escalabilidad**: Se pueden agregar múltiples consumers
4. **Confiabilidad**: Mensajes persistentes y acknowledgment manual
5. **Trazabilidad completa**: Todas las operaciones quedan registradas
6. **Consulta flexible**: API con múltiples filtros
7. **Independencia de base de datos**: MongoDB optimizado para logs

## Próximas Mejoras

- [ ] Dead Letter Queue para mensajes fallidos
- [ ] Retención automática de logs antiguos
- [ ] Dashboard de métricas de auditoría
- [ ] Alertas por eventos críticos
- [ ] Exportación de logs en formato CSV/JSON
- [ ] Firma digital de logs para inmutabilidad

