# Servicio de Auditoría - API REST

Microservicio para la gestión de auditoría desarrollado con Ruby on Rails 7.1 y MongoDB usando Mongoid.

## 📋 Tabla de Contenidos

- [🛠 Requisitos](#-requisitos)
- [⚙️ Configuración](#️-configuración)
- [🗄️ Base de Datos](#️-base-de-datos)
- [🚀 Ejecución](#-ejecución)
- [📡 API Endpoints](#-api-endpoints)
- [🧪 Testing](#-testing)
- [📊 Modelo de Datos](#-modelo-de-datos)
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
rails server
# o
bin/rails server -p 3000
```

El servicio estará disponible en: `http://localhost:3000`

### Verificar el servicio

```bash
curl http://localhost:3000/api/v1/health_check
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
http://localhost:3000/api/v1
```

### Health Check

**GET** `/api/v1/health_check`

Verifica el estado del servicio.

**Respuesta:**
```json
{
  "status": "Audit Service is running"
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
rails test test/models/

# Tests del controlador
rails test test/controllers/
```

## 📊 Modelo de Datos

### Crear modelos con Mongoid

Los modelos en este servicio heredan de `Mongoid::Document`. Ejemplo:

```ruby
class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :action, type: String
  field :user_id, type: Integer
  field :resource_type, type: String
  field :resource_id, type: String
  field :changes, type: Hash

  # Índices
  index({ user_id: 1 })
  index({ created_at: -1 })

  # Validaciones
  validates :action, presence: true
  validates :user_id, presence: true
end
```

### Características de Mongoid

- **Timestamps automáticos**: Usa `include Mongoid::Timestamps` para `created_at` y `updated_at`
- **Validaciones**: Similar a Active Record
- **Asociaciones**: Soporta `has_many`, `belongs_to`, `has_and_belongs_to_many`
- **Índices**: Define índices para mejorar el rendimiento
- **Scopes**: Define scopes para consultas reutilizables

## 🔧 Comandos Útiles

```bash
# Ver rutas disponibles
rails routes

# Consola interactiva
rails console

# Verificar sintaxis (Rubocop)
rubocop

# Análisis de seguridad
brakeman

# Generar un nuevo modelo con Mongoid
rails generate model AuditLog action:string user_id:integer
```

## 📝 Notas Adicionales

- El servicio utiliza MongoDB como base de datos NoSQL
- Se utiliza Mongoid 8.1 como ODM (Object-Document Mapper)
- Las colecciones se crean automáticamente al insertar el primer documento
- Los modelos incluyen automáticamente `created_at` y `updated_at` con `Mongoid::Timestamps`
- Rails 7.1 es compatible con Mongoid 8.1

## 🐛 Solución de Problemas

### Error de conexión a MongoDB

Si tienes problemas de conexión a MongoDB, verifica:

1. Que MongoDB esté corriendo (`brew services start mongodb-community` en macOS)
2. Las credenciales en `.env` sean correctas
3. El puerto 27017 esté disponible
4. Que el usuario de MongoDB tenga permisos para crear bases de datos

### Verificar estado de MongoDB

```bash
# Verificar que MongoDB esté corriendo
brew services list

# O verificar el proceso
ps aux | grep mongod

# Conectar a MongoDB desde la consola
mongosh
```

### Limpiar base de datos de desarrollo

```bash
# Conectar a MongoDB
mongosh

# Seleccionar la base de datos
use audit_service_development

# Eliminar todas las colecciones
db.dropDatabase()
```

### Problemas con Mongoid

Si encuentras problemas con Mongoid:

```bash
# Verificar la configuración
rails console
> Mongoid.clients

# Verificar la conexión
> Mongoid.default_client.database.name
```
