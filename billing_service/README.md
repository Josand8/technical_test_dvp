# Servicio de Facturación - API REST

Microservicio para la gestión de facturas desarrollado con Ruby on Rails 8.1 y PostgreSQL.

**Nota importante:** Este servicio comparte la misma base de datos con el servicio de clientes (`clients_service`).

## 🚀 Inicio Rápido

```bash
# 1. Instalar dependencias
bundle install

# 2. Configurar variables de entorno
cp .env.example .env  # o crear manualmente

# 3. Ejecutar migraciones (requiere clients_service configurado)
rails db:migrate

# 4. Cargar datos de prueba (opcional)
rails db:seed

# 5. Iniciar el servidor
rails server -p 3001
```

El servicio estará disponible en: `http://127.0.0.1:3001`

## 📋 Tabla de Contenidos

- [🛠 Requisitos](#-requisitos)
- [⚙️ Configuración](#️-configuración)
- [🗄️ Base de Datos](#️-base-de-datos)
- [🚀 Ejecución](#-ejecución)
- [📡 API Endpoints](#-api-endpoints)
- [📊 Modelo de Datos](#-modelo-de-datos)
- [🔗 Integraciones](#-integraciones)
- [🔧 Comandos Útiles](#-comandos-útiles)
- [🐛 Solución de Problemas](#-solución-de-problemas)

## 🛠 Requisitos

- Ruby 3.3.6 o superior
- Rails 8.1.1
- PostgreSQL 14 o superior
- Servicio de clientes (`clients_service`) configurado y corriendo
- Gema `dotenv-rails` para manejo de variables de entorno (desarrollo)

## ⚙️ Configuración

### 1. Instalar dependencias

```bash
bundle install
```

### 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto:

```env
# PostgreSQL Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres

# Services Configuration
CLIENTS_SERVICE_URL=http://127.0.0.1:3000
AUDIT_SERVICE_URL=http://localhost:3002

# Tributary Authority (optional) solo como ejemplo de una intregración futura
TRIBUTARY_AUTHORITY_COUNTRY=other  # colombia, other
```

## 🗄️ Base de Datos

### Ejecutar migraciones

**Importante:** El servicio de clientes debe estar configurado primero.

```bash
# Ejecutar migraciones (crea la tabla invoices)
rails db:migrate

# Cargar datos de ejemplo (opcional)
rails db:seed
```

### Estructura de la tabla `invoices`

| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| id | SERIAL | Identificador único | Primary Key |
| client_id | INTEGER | ID del cliente | NOT NULL, Foreign Key → clients.id |
| invoice_number | VARCHAR | Número de factura | NOT NULL, único, auto-generado |
| issue_date | DATE | Fecha de emisión | NOT NULL, default: fecha actual |
| due_date | DATE | Fecha de vencimiento | Opcional |
| subtotal | DECIMAL(15,2) | Subtotal | NOT NULL, >= 0 |
| tax | DECIMAL(15,2) | Impuestos | Default: 0.0, >= 0 |
| total | DECIMAL(15,2) | Total | NOT NULL, calculado automáticamente |
| status | VARCHAR | Estado | pending, paid, overdue, cancelled |
| notes | TEXT | Notas adicionales | Opcional |
| created_at | TIMESTAMP | Fecha de creación | |

### Índices

- `index_invoices_on_invoice_number` (UNIQUE)
- `index_invoices_on_status`

## 🚀 Ejecución

### Modo desarrollo

```bash
# Puerto 3001 para no conflictuar con clients_service
rails server -p 3001
```

El servicio estará disponible en: `http://127.0.0.1:3001`

### Verificar el servicio

```bash
curl http://127.0.0.1:3001/api/v1/health_check
```

Respuesta esperada:
```json
{
  "status": "Billing Service is running"
}
```

## 📡 API Endpoints

### Base URL
```
http://127.0.0.1:3001/api/v1
```

### Health Check

**GET** `/api/v1/health_check`

Verifica el estado del servicio.

**Respuesta:**
```json
{
  "status": "Billing Service is running"
}
```

---

### Listar Facturas

**GET** `/api/v1/facturas`

Obtiene la lista de todas las facturas con información del cliente.

**Parámetros de consulta (opcionales):**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| client_id | Integer | Filtrar por ID de cliente |
| status | String | Filtrar por estado (pending, paid, overdue, cancelled) |
| fechaInicio | Date | Filtrar facturas desde esta fecha (formato: YYYY-MM-DD) |
| fechaFin | Date | Filtrar facturas hasta esta fecha (formato: YYYY-MM-DD) |

**Ejemplo de solicitud:**
```bash
# Listar todas las facturas
curl "http://127.0.0.1:3001/api/v1/facturas"

# Filtrar por cliente
curl "http://127.0.0.1:3001/api/v1/facturas?client_id=1"

# Filtrar por estado
curl "http://127.0.0.1:3001/api/v1/facturas?status=pending"

# Filtrar por rango de fechas
curl "http://127.0.0.1:3001/api/v1/facturas?fechaInicio=2025-01-01&fechaFin=2025-12-31"

# Filtrar facturas desde una fecha
curl "http://127.0.0.1:3001/api/v1/facturas?fechaInicio=2025-11-01"
```

**Respuesta exitosa (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "client_id": 1,
      "invoice_number": "INV-20251112-0001",
      "issue_date": "2025-11-12",
      "due_date": "2025-12-12",
      "subtotal": "1000.0",
      "tax": "190.0",
      "total": "1190.0",
      "status": "pending",
      "notes": "Factura por servicios de consultoría",
      "created_at": "2025-11-12T09:30:00.000Z",
      "client": {
        "id": 1,
        "name": "Juan Pérez",
        "email": "juanperez@gmail.com"
      }
    }
  ],
  "total_invoices": 5
}
```

**Respuesta de error (400 Bad Request):**
```json
{
  "success": false,
  "message": "Formato de fecha inválido. Use formato YYYY-MM-DD"
}
```

---

### Obtener Factura

**GET** `/api/v1/facturas/:id`

Obtiene los detalles de una factura específica con información completa del cliente.

**Parámetros de ruta:**
- `id` (requerido): ID de la factura

**Ejemplo de solicitud:**
```bash
curl http://127.0.0.1:3001/api/v1/facturas/1
```

**Respuesta exitosa (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "client_id": 1,
    "invoice_number": "INV-20251112-0001",
    "issue_date": "2025-11-12",
    "due_date": "2025-12-12",
    "subtotal": "1000.0",
    "tax": "190.0",
    "total": "1190.0",
    "status": "pending",
    "notes": "Factura por servicios de consultoría",
    "created_at": "2025-11-12T09:30:00.000Z",
    "client": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juanperez@gmail.com",
      "identification": "12345678",
      "address": "Carrera 7 #23-45, Bogotá"
    }
  }
}
```

**Respuesta de error (404 Not Found):**
```json
{
  "success": false,
  "message": "Factura no encontrada"
}
```

---

### Crear Factura

**POST** `/api/v1/facturas`

Crea una nueva factura para un cliente existente.

**Headers:**
```
Content-Type: application/json
```

**Cuerpo de la solicitud:**
```json
{
  "invoice": {
    "client_id": 1,
    "subtotal": 1000.00,
    "tax": 190.00,
    "due_date": "2025-12-31",
    "status": "pending",
    "notes": "Servicios profesionales"
  }
}
```

**Campos:**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| client_id | Integer | Sí | ID del cliente (debe existir en la tabla clients) |
| subtotal | Decimal | Sí | Monto antes de impuestos (>= 0) |
| tax | Decimal | No | Impuestos (>= 0, default: 0.0) |
| invoice_number | String | No | Se genera automáticamente si no se proporciona |
| issue_date | Date | No | Default: fecha actual |
| due_date | Date | No | Fecha de vencimiento |
| status | String | No | pending, paid, overdue, cancelled (default: pending) |
| notes | Text | No | Notas adicionales |

**Nota:** El campo `total` se calcula automáticamente como `subtotal + tax`.

**Ejemplo de solicitud:**
```bash
curl -X POST http://127.0.0.1:3001/api/v1/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "client_id": 1,
      "subtotal": 1000.00,
      "tax": 190.00,
      "due_date": "2025-12-31",
      "notes": "Servicios de consultoría"
    }
  }'
```

**Respuesta exitosa (201 Created):**
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 6,
    "client_id": 1,
    "invoice_number": "INV-20251112-0006",
    "issue_date": "2025-11-12",
    "due_date": "2025-12-31",
    "subtotal": "1000.0",
    "tax": "190.0",
    "total": "1190.0",
    "status": "pending",
    "notes": "Servicios de consultoría",
    "created_at": "2025-11-12T10:00:00.000Z",
    "client": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juanperez@gmail.com"
    }
  }
}
```

**Respuesta de error (422 Unprocessable Entity):**
```json
{
  "success": false,
  "message": "No se pudo crear la factura",
  "errors": [
    "Client no puede estar vacío",
    "Subtotal debe ser mayor o igual a 0"
  ]
}
```

---

## 📊 Modelo de Datos

### Relaciones

- `Invoice` tiene una referencia a `Client` mediante `client_id`
- **Nota importante**: No existe una Foreign Key a nivel de base de datos hacia la tabla `clients`
- La validación de existencia del cliente se realiza mediante el servicio `ClientsService` que hace llamadas HTTP al `clients_service`
- Esto permite mantener la independencia entre los microservicios mientras se comparte la base de datos

### Validaciones del modelo Invoice

- **client_id**: 
  - Presencia requerida
  - **Validación personalizada**: Verifica la existencia del cliente mediante llamada HTTP al `clients_service`
  - Mensaje de error: "el cliente no existe en el servicio de clientes"

- **invoice_number**: 
  - Presencia requerida
  - Único en la base de datos
  - Se genera automáticamente en formato: `INV-YYYYMMDD-XXXX`
  - Mensaje de error: "no puede estar vacío" / "ya está registrado"

- **issue_date**: 
  - Presencia requerida
  - Default: fecha actual (solo en creación)
  - Mensaje de error: "no puede estar vacío"

- **subtotal**: 
  - Presencia requerida
  - Debe ser >= 0
  - Mensaje de error: "no puede estar vacío" / "debe ser mayor o igual a 0"

- **tax**: 
  - Opcional (permite nil)
  - Debe ser >= 0
  - Default: 0.0
  - Mensaje de error: "debe ser mayor o igual a 0"

- **total**: 
  - Presencia requerida
  - Se calcula automáticamente como `subtotal + tax`
  - Debe ser >= 0
  - Mensaje de error: "no puede estar vacío" / "debe ser mayor o igual a 0"

- **status**: 
  - Debe ser uno de: `pending`, `paid`, `overdue`, `cancelled`
  - Default: `pending`
  - Mensaje de error: "debe ser pending, paid, overdue o cancelled"

### Scopes

- `Invoice.pending` - Retorna facturas pendientes
- `Invoice.paid` - Retorna facturas pagadas
- `Invoice.overdue` - Retorna facturas vencidas
- `Invoice.by_client(client_id)` - Filtra por cliente

### Callbacks

- `before_validation :generate_invoice_number` - Genera número de factura automáticamente (solo en creación)
- `before_validation :calculate_total` - Calcula el total automáticamente
- `before_validation :set_default_issue_date` - Establece fecha de emisión por defecto (solo en creación)
- `before_validation :check_overdue_status` - Actualiza automáticamente facturas pendientes vencidas a estado 'overdue'

## 🔧 Comandos Útiles

```bash
# Ver rutas disponibles
rails routes

# Consola interactiva
rails console

# Verificar sintaxis (Rubocop)
rubocop

# Ver facturas en consola
rails console
> Invoice.includes(:client).all
```

## 🔗 Integraciones

### Clients Service

El servicio se comunica con `clients_service` para:
- Validar existencia de clientes antes de crear facturas
- Obtener información del cliente en las respuestas JSON

**Configuración:** `CLIENTS_SERVICE_URL=http://127.0.0.1:3000`

### Audit Service

Registra automáticamente eventos de auditoría:
- ✅ Creación de facturas
- ✅ Consulta de facturas
- ✅ Errores de validación
- ✅ Recursos no encontrados

**Configuración:** `AUDIT_SERVICE_URL=http://localhost:3002`

### Integración Tributaria (Factory Method)

Arquitectura preparada para integración futura con entidades tributarias (DIAN, SAT, SUNAT, etc.).

**Archivos:**
- `app/services/tributary_authorities/` - Adaptadores y Factory
- Ver [DIAN_FUTURE_IMPLEMENTATION.md](./DIAN_FUTURE_IMPLEMENTATION.md) para más detalles

**Configuración:** `TRIBUTARY_AUTHORITY_COUNTRY=colombia|other`

## 📝 Notas Adicionales

- **Base de datos compartida**: Comparte PostgreSQL con `clients_service`
- **Número de factura**: Auto-generado en formato `INV-YYYYMMDD-XXXX`
- **Cálculo automático**: `total = subtotal + tax`
- **Detección de vencidas**: Facturas `pending` con `due_date` pasada se marcan como `overdue`
- **Puerto recomendado**: 3001

## 🐛 Solución de Problemas

### Error: Cliente no encontrado al crear factura

Este error ocurre cuando el `client_id` proporcionado no existe en el servicio de clientes. Verifica:

1. **Que el servicio de clientes esté corriendo:**
   ```bash
   curl http://127.0.0.1:3000/api/v1/health_check
   ```

2. **Que el cliente exista:**
   ```bash
   curl http://127.0.0.1:3000/api/v1/clientes/{client_id}
   ```

3. **Que la variable `CLIENTS_SERVICE_URL` esté configurada correctamente** en el archivo `.env`

### Error de conexión a PostgreSQL

Asegúrate de que:
- El servicio de clientes ya tiene configurada la base de datos y las migraciones ejecutadas
- Las variables de entorno de PostgreSQL estén correctamente configuradas en el archivo `.env`
- PostgreSQL esté corriendo en tu sistema

### Las facturas no incluyen información del cliente

Verifica que:
- El servicio de clientes esté corriendo y accesible
- La URL configurada en `CLIENTS_SERVICE_URL` sea correcta
- Revisa los logs del servicio para ver si hay errores de conexión

### Estructura del Proyecto

```
billing_service/
├── app/
│   ├── controllers/api/v1/
│   │   └── invoices_controller.rb
│   ├── models/
│   │   └── invoice.rb
│   └── services/
│       ├── clients_service.rb
│       ├── audit_service.rb
│       └── tributary_authorities/
│           ├── base_adapter.rb
│           ├── dian_adapter.rb
│           ├── other_adapter.rb
│           └── factory.rb
└── db/migrate/
    └── 20251112092641_create_invoices.rb
```
