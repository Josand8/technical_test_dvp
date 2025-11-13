# Technical Test DVP - Microservicios

Sistema de microservicios para gestión de clientes y facturación con auditoría distribuida.

## Arquitectura

El proyecto está compuesto por 3 microservicios independientes:

### 1. **Clients Service** (Puerto 3001)
- Gestión de clientes
- Base de datos: PostgreSQL
- API REST para CRUD de clientes

### 2. **Billing Service** (Puerto 3002)
- Gestión de facturas
- Base de datos: PostgreSQL
- Integración con Clients Service
- API REST para CRUD de facturas

### 3. **Audit Service** (Puerto 3000)
- Sistema de auditoría centralizado
- Base de datos: MongoDB
- Consumer de eventos de RabbitMQ
- API REST para consulta de logs

## 🎯 Sistema de Auditoría con Message Broker

Se ha implementado un **sistema completo de auditoría distribuida** que utiliza **RabbitMQ** como message broker. Todos los eventos de los servicios de clientes y facturación se registran automáticamente de forma asíncrona.

### Características principales:
- ✅ Auditoría automática de todas las operaciones (Create, Read, Update, Delete)
- ✅ Comunicación asíncrona via RabbitMQ
- ✅ Persistencia en MongoDB
- ✅ Tolerante a fallos
- ✅ No intrusivo en el flujo principal
- ✅ API de consulta con filtros avanzados

**📖 Ver documentación completa:** [AUDITORIA.md](./AUDITORIA.md)

## Quick Start

### Prerrequisitos

- Ruby 3.2+
- PostgreSQL
- MongoDB
- RabbitMQ
- Docker & Docker Compose (recomendado)

### 1. Iniciar infraestructura

```bash
# Iniciar RabbitMQ, MongoDB y PostgreSQL
docker-compose -f docker-compose.rabbitmq.yml up -d
```

### 2. Configurar servicios

```bash
# Clients Service
cd clients_service
bundle install
rails db:create db:migrate
rails server -p 3001

# Billing Service
cd ../billing_service
bundle install
rails db:create db:migrate
rails server -p 3002

# Audit Service
cd ../audit_service
bundle install
rails server -p 3000

# Audit Consumer (en otra terminal)
cd audit_service
bundle exec rake audit:consumer
```

### 3. Probar el sistema

```bash
# Crear un cliente
curl -X POST http://localhost:3001/api/v1/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "John Doe",
      "email": "john@example.com",
      "identification": "12345678"
    }
  }'

# Consultar logs de auditoría
curl http://localhost:3000/api/v1/auditoria
```

## Endpoints Principales

### Clients Service (3001)
- `GET /api/v1/clients` - Listar clientes
- `GET /api/v1/clients/:id` - Ver cliente
- `POST /api/v1/clients` - Crear cliente

### Billing Service (3002)
- `GET /api/v1/invoices` - Listar facturas
- `GET /api/v1/invoices/:id` - Ver factura
- `POST /api/v1/invoices` - Crear factura

### Audit Service (3000)
- `GET /api/v1/auditoria` - Listar logs con filtros
- `GET /api/v1/auditoria/:resource_id` - Logs de un recurso específico

## Monitoreo

### RabbitMQ Management UI
- URL: http://localhost:15672
- Usuario: `guest`
- Contraseña: `guest`

## Tecnologías Utilizadas

- **Backend**: Ruby on Rails 8.1
- **Bases de datos**: PostgreSQL, MongoDB
- **Message Broker**: RabbitMQ
- **ODM**: Mongoid
- **AMQP Client**: Bunny

## Estructura del Proyecto

```
technical_test_dvp/
├── clients_service/       # Servicio de clientes
├── billing_service/       # Servicio de facturación
├── audit_service/         # Servicio de auditoría
├── docker-compose.rabbitmq.yml  # Infraestructura
├── AUDITORIA.md          # Documentación de auditoría
└── README.md             # Este archivo
```

## Documentación Adicional

- [Sistema de Auditoría Completo](./AUDITORIA.md)
- [Configuración de RabbitMQ](./AUDITORIA.md#configuración)
- [API de Auditoría](./AUDITORIA.md#api-de-consulta-de-logs)
- [Troubleshooting](./AUDITORIA.md#troubleshooting)

## Licencia

MIT
