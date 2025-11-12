# Servicio de Clientes - API REST

Microservicio para la gestión de clientes desarrollado con Ruby on Rails 8.1 y PostgreSQL.

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Configuración](#configuración)
- [Base de Datos](#base-de-datos)
- [Ejecución](#ejecución)
- [API Endpoints](#api-endpoints)
- [Testing](#testing)
- [Modelo de Datos](#modelo-de-datos)

## 🛠 Requisitos

- Ruby 3.3.6 o superior
- Rails 8.1.1
- PostgreSQL 14 o superior

## ⚙️ Configuración

### 1. Instalar dependencias

```bash
bundle install
```

### 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto:

```env
# PostgreSQL Database Configuration
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres
```

## 🗄️ Base de Datos

### Crear la base de datos y ejecutar migraciones

```bash
# Crear la base de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# Cargar datos de ejemplo (opcional)
rails db:seed
```

### Estructura de la tabla `clients`

| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| id | SERIAL | Identificador único | Primary Key |
| name | VARCHAR | Nombre del cliente | NOT NULL, 2-100 caracteres |
| identification | VARCHAR | Identificación del cliente | Único, máximo 20 caracteres |
| email | VARCHAR | Email del cliente | NOT NULL, único, formato válido |
| address | TEXT | Dirección | Máximo 500 caracteres |
| created_at | TIMESTAMP | Fecha de creación | |
| updated_at | TIMESTAMP | Fecha de actualización | |

### Índices

- `index_clients_on_email` (UNIQUE)
- `index_clients_on_identification` (UNIQUE)

## 🚀 Ejecución

### Modo desarrollo

```bash
rails server
# o
bin/rails server -p 3000
```

El servicio estará disponible en: `http://127.0.0.1:3000`


### Verificar el servicio

```bash
curl http://127.0.0.1:3000/api/v1/health_check
```

Respuesta esperada:
```json
{
  "status": "Clients Service is running"
}
```

## 📡 API Endpoints

### Base URL
```
http://127.0.0.1:3000/api/v1
```

**Nota:** El recurso de clientes está disponible en la ruta `/clientes` (en español).

### Health Check

**GET** `/api/v1/health_check`

Verifica el estado del servicio.

**Respuesta:**
```json
{
  "status": "Clients Service is running"
}
```

---

### Listar Clientes

**GET** `/api/v1/clientes`

Obtiene la lista de todos los clientes.

**Parámetros de consulta (opcionales):**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| search | String | Búsqueda por nombre o email (case insensitive) |

**Ejemplo de solicitud:**
```bash
# Listar todos los clientes
curl "http://127.0.0.1:3000/api/v1/clientes"

# Buscar clientes por nombre o email
curl "http://127.0.0.1:3000/api/v1/clientes?search=juan"
```

**Respuesta exitosa (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Juan Pérez",
      "identification": "12345678",
      "email": "juanperez@gmail.com",
      "address": "Carrera 7 #23-45, Bogotá",
      "created_at": "2024-11-11T23:46:38.000Z"
    }
  ],
  "total_clients": 1
}
```

---

### Obtener Cliente

**GET** `/api/v1/clientes/:id`

Obtiene los detalles de un cliente específico.

**Parámetros de ruta:**
- `id` (requerido): ID del cliente

**Ejemplo de solicitud:**
```bash
curl http://127.0.0.1:3000/api/v1/clientes/1
```

**Respuesta exitosa (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Juan Pérez",
    "identification": "12345678",
    "email": "juanperez@gmail.com",
    "address": "Carrera 7 #23-45, Bogotá",
    "created_at": "2024-11-11T23:46:38.000Z"
  }
}
```

**Respuesta de error (404 Not Found):**
```json
{
  "success": false,
  "message": "Cliente no encontrado"
}
```

---

### Crear Cliente

**POST** `/api/v1/clientes`

Crea un nuevo cliente.

**Headers:**
```
Content-Type: application/json
```

**Cuerpo de la solicitud:**
```json
{
  "client": {
    "name": "Nuevo Cliente",
    "identification": "87654321",
    "email": "nuevo@example.com",
    "address": "Calle Nueva 456"
  }
}
```

**Campos:**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| name | String | Sí | Nombre del cliente (2-100 caracteres) |
| identification | String | No | Identificación del cliente (único, máximo 20 caracteres) |
| email | String | Sí | Email válido y único |
| address | String | No | Dirección (máximo 500 caracteres) |

**Ejemplo de solicitud:**
```bash
curl -X POST http://127.0.0.1:3000/api/v1/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "Nuevo Cliente",
      "identification": "87654321",
      "email": "nuevo@example.com",
      "address": "Calle Nueva 456"
    }
  }'
```

**Respuesta exitosa (201 Created):**
```json
{
  "success": true,
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 7,
    "name": "Nuevo Cliente",
    "identification": "87654321",
    "email": "nuevo@example.com",
    "address": "Calle Nueva 456",
    "created_at": "2024-11-11T23:46:38.000Z"
  }
}
```

**Respuesta de error (422 Unprocessable Entity):**
```json
{
  "success": false,
  "message": "No se pudo crear el cliente",
  "errors": [
    "Email no tiene un formato válido",
    "Name no puede estar vacío"
  ]
}
```

---

## 🧪 Testing

### Ejecutar todos los tests

```bash
rails test
```

### Ejecutar tests específicos

```bash
# Tests del modelo
rails test test/models/client_test.rb

# Tests del controlador
rails test test/controllers/api/v1/clients_controller_test.rb
```

### Tests con cobertura

El proyecto incluye tests para:

- ✅ Validaciones del modelo (name, email, identification, address)
- ✅ Callbacks y normalizaciones (email lowercase, identificación sin espacios)
- ✅ Scopes y consultas (búsqueda por nombre y email)
- ✅ Endpoints de la API (index, show, create)
- ✅ Respuestas de error (404, 422)
- ✅ Búsqueda por nombre y email

## 📊 Modelo de Datos

### Validaciones

El modelo `Client` incluye las siguientes validaciones:

- **name**: 
  - Presencia requerida
  - Longitud entre 2 y 100 caracteres

- **identification**: 
  - Máximo 20 caracteres
  - Único
  - Normalizado (sin espacios) antes de guardar
  - Opcional

- **email**: 
  - Presencia requerida
  - Formato válido (RFC 2822)
  - Único (case insensitive)
  - Normalizado a minúsculas antes de guardar

- **address**: 
  - Máximo 500 caracteres
  - Opcional

### Scopes

- `Client.by_name(name)` - Busca por nombre (case insensitive)
- `Client.by_email(email)` - Busca por email (case insensitive)

## 🔧 Comandos Útiles

```bash
# Reiniciar la base de datos
rails db:reset

# Ver rutas disponibles
rails routes

# Consola interactiva
rails console

# Verificar sintaxis (Rubocop)
rubocop

# Análisis de seguridad
brakeman
```

## 📝 Notas Adicionales

- El servicio utiliza PostgreSQL como motor de base de datos compartido entre microservicios
- Todos los endpoints retornan JSON
- Los emails se normalizan automáticamente a minúsculas antes de guardar
- Los números de identificación se normalizan eliminando espacios antes de guardar
- Las búsquedas no distinguen entre mayúsculas y minúsculas (case insensitive)
- El campo `updated_at` no se incluye en las respuestas JSON

## 🐛 Solución de Problemas

### Error de conexión a PostgreSQL

Si tienes problemas de conexión a PostgreSQL, verifica:

1. Que PostgreSQL esté corriendo (`brew services start postgresql` en macOS)
2. Las credenciales en `.env` sean correctas
3. El usuario de PostgreSQL tenga permisos para crear bases de datos
4. El puerto 5432 esté disponible

### Error en las migraciones

Si las migraciones fallan:

```bash
# Verificar el estado de las migraciones
rails db:migrate:status

# Rollback de la última migración
rails db:rollback

# Ejecutar migración específica
rails db:migrate:up VERSION=20251111234638
```

## 👥 Contribución

Este es un proyecto de prueba técnica. Para cualquier consulta o sugerencia, contacta al equipo de desarrollo.
