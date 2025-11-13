# 🧑‍💼 Servicio de Clientes

Microservicio para gestionar clientes del sistema de facturación. Proporciona operaciones CRUD para clientes y se integra con el servicio de auditoría.

## 🛠️ Tecnologías

- **Ruby**: 3.4.3
- **Rails**: 8.0.4
- **Base de datos**: Oracle Enhanced Adapter (~> 8.0.0)
- **Testing**: RSpec
- **Docker**: Compatible

## 📋 Requisitos Previos

- Ruby 3.4.3
- Bundler 2.4.19
- Oracle Database XE (contenedor Docker)
- Docker y Docker Compose (para entorno completo)

## 🔧 Variables de Entorno

Crea un archivo `.env` en la raíz del servicio con las siguientes variables:

```env
# Base de datos Oracle
ORACLE_PASSWORD=developmentpass
RAILS_ENV=development

# Servicios externos
AUDIT_SERVICE_URL=http://audit_service:3002
```

## 🚀 Instalación

### Opción 1: Con Docker (Recomendado)

```bash
# Desde la raíz del proyecto principal
docker-compose up clients_service
```

### Opción 2: Local

```bash
# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create
rails db:migrate

# Iniciar servidor
rails server -p 3000
```

## 📡 API Endpoints

### Health Check
```
GET /api/v1/health_check
```

### Listar Clientes
```
GET /api/v1/clientes
```

**Parámetros opcionales:**
- `search`: Busca por nombre o email

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "identification": "123456789",
      "address": "Calle 123",
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "total_clients": 1
}
```

### Obtener Cliente
```
GET /api/v1/clientes/:id
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "identification": "123456789",
    "address": "Calle 123",
    "created_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Crear Cliente
```
POST /api/v1/clientes
Content-Type: application/json
```

**Body:**
```json
{
  "client": {
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "identification": "123456789",
    "address": "Calle 123"
  }
}
```

**Respuesta exitosa (201):**
```json
{
  "success": true,
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "identification": "123456789",
    "address": "Calle 123",
    "created_at": "2024-01-01T00:00:00.000Z"
  }
}
```

## 📝 Validaciones

### Campo `name`
- Obligatorio
- Longitud: 2-100 caracteres

### Campo `email`
- Obligatorio
- Formato válido de email
- Único en el sistema

### Campo `identification`
- Opcional
- Único si se proporciona
- Máximo 20 caracteres

### Campo `address`
- Opcional
- Máximo 500 caracteres

## 🧪 Testing

```bash
# Ejecutar todos los tests
bundle exec rspec

# Ejecutar tests específicos
bundle exec rspec spec/models/client_spec.rb
bundle exec rspec spec/controllers/api/v1/clients_controller_spec.rb
```

## 🔍 Ejemplos de Uso

### Crear un cliente
```bash
curl -X POST http://localhost:3000/api/v1/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "María García",
      "email": "maria@example.com",
      "identification": "987654321",
      "address": "Avenida Principal 456"
    }
  }'
```

### Buscar clientes
```bash
# Buscar por nombre o email
curl "http://localhost:3000/api/v1/clientes?search=maria"
```

### Obtener un cliente específico
```bash
curl http://localhost:3000/api/v1/clientes/1
```

## 🔗 Integración con Otros Servicios

### Servicio de Auditoría
Este servicio registra automáticamente en el servicio de auditoría:
- Creación de clientes
- Lectura de clientes
- Errores en operaciones

## 🐛 Manejo de Errores

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
  "message": "No se pudo crear el cliente",
  "errors": [
    "Email ya está registrado",
    "Name no puede estar vacío"
  ]
}
```

## 📊 Estructura del Proyecto

```
clients_service/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       └── clients_controller.rb
│   ├── models/
│   │   └── client.rb
│   └── services/
│       └── audit_service.rb
├── config/
│   ├── database.yml
│   └── routes.rb
├── db/
│   └── migrate/
├── spec/
│   ├── controllers/
│   ├── factories/
│   └── models/
└── Dockerfile
```

## 🔄 Scopes Disponibles

```ruby
# Buscar por nombre (case insensitive)
Client.by_name("juan")

# Buscar por email (case insensitive)
Client.by_email("juan@example.com")
```

## 🏷️ Versionado

**Versión actual:** v1
**Puerto por defecto:** 3000

## 📚 Documentación Adicional

Para más información sobre la arquitectura completa del sistema, consulta el README principal del proyecto.
