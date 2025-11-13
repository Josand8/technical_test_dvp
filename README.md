# 🏢 Sistema de Facturación - Microservicios

Sistema de facturación basado en arquitectura de microservicios desarrollado en Ruby on Rails. Consta de tres servicios independientes que trabajan en conjunto para gestionar clientes, facturas y auditoría.

## 📦 Servicios

- **🧑‍💼 Clients Service** (Puerto 3000): Gestión de clientes
- **📄 Billing Service** (Puerto 3001): Gestión de facturas
- **🔍 Audit Service** (Puerto 3002): Registro de logs de auditoría

## 🛠️ Tecnologías

- **Ruby**: 3.4.3
- **Rails**: 8.0.4 (Clients & Billing), 7.1.0 (Audit)
- **Bases de datos**: Oracle Database XE 18.4.0, MongoDB
- **Docker & Docker Compose**: Para orquestación de servicios

## 🏗️ Arquitectura

Este proyecto implementa una arquitectura de microservicios siguiendo los principios de **Microservicios**, **Clean Architecture** y **MVC**.

### 🔄 Microservicios

El sistema está dividido en tres microservicios independientes, cada uno con su propia responsabilidad:

- **Separación de responsabilidades**: Cada servicio gestiona un dominio específico (clientes, facturas, auditoría)
- **Independencia de bases de datos**: 
  - `clients_service` y `billing_service` usan Oracle Database
  - `audit_service` usa MongoDB (NoSQL)
- **Comunicación entre servicios**: Los servicios se comunican mediante HTTP REST, manteniendo un acoplamiento débil
- **Despliegue independiente**: Cada servicio puede desplegarse y escalarse de forma independiente
- **Tecnologías heterogéneas**: Aunque todos usan Rails, cada servicio puede evolucionar independientemente

### 🧹 Clean Architecture

La estructura de cada servicio sigue los principios de Clean Architecture:

- **Separación de capas**:
  - **Controllers** (`app/controllers/`): Manejan las peticiones HTTP y validaciones básicas
  - **Services** (`app/services/`): Contienen la lógica de negocio y comunicación entre servicios
  - **Models** (`app/models/`): Representan las entidades del dominio y validaciones
- **Independencia del framework**: La lógica de negocio está en los servicios, no acoplada a Rails
- **Dependencias invertidas**: Los controladores dependen de los servicios, no al revés
- **Testabilidad**: Cada capa puede probarse de forma independiente

**Ejemplo de flujo**:
```
Request → Controller → Service → Model → Database
                ↓
         Audit Service (logging)
```

### 🎯 MVC (Model-View-Controller)

Aunque es una API REST (sin vistas), el patrón MVC se aplica de la siguiente manera:

- **Model**: 
  - Representa las entidades del dominio (`Client`, `Invoice`, `AuditLog`)
  - Contiene validaciones y lógica de dominio
  - Se comunica con la base de datos
- **Controller**: 
  - Maneja las peticiones HTTP (`Api::V1::ClientsController`, `Api::V1::InvoicesController`)
  - Valida parámetros de entrada
  - Orquesta la llamada a servicios y modelos
  - Formatea las respuestas JSON
- **View**: 
  - En este caso, las respuestas JSON actúan como "vistas"
  - Se formatean en los controladores usando `render json:`

**Ejemplo en Clients Service**:
```ruby
# Controller (app/controllers/api/v1/clients_controller.rb)
def create
  @client = Client.new(client_params)  # Model
  if @client.save
    AuditService.log_create(...)        # Service
    render json: {...}                   # View (JSON)
  end
end
```

### 🔗 Integración entre Principios

Los tres principios trabajan en conjunto:

1. **Microservicios** proporcionan la separación a nivel de sistema
2. **Clean Architecture** organiza el código dentro de cada microservicio
3. **MVC** estructura la capa de presentación (API) de cada servicio

Esta combinación permite un sistema escalable, mantenible y fácil de probar.

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Docker** (versión 20.10 o superior)
- **Docker Compose** (versión 2.0 o superior)
- **Git** (para clonar el repositorio)

### Verificar instalación

```bash
docker --version
docker-compose --version
git --version
```

## 🚀 Instalación y Ejecución

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/Josand8/technical_test_dvp.git
cd technical_test_dvp
```

### Paso 2: Configurar variables de entorno

Crea los archivos `.env` para cada servicio con las siguientes variables:

#### `clients_service/.env`

```env
ORACLE_PASSWORD=developmentpass
RAILS_ENV=development
AUDIT_SERVICE_URL=http://audit:3002
```

#### `billing_service/.env`

```env
ORACLE_PASSWORD=developmentpass
RAILS_ENV=development
CLIENTS_SERVICE_URL=http://clients:3000
AUDIT_SERVICE_URL=http://audit:3002
```

#### `audit_service/.env`

```env
MONGODB_HOST=mongodb
MONGODB_PORT=27017
RAILS_ENV=development
```

### Paso 3: Construir y levantar los servicios

Desde la raíz del proyecto, ejecuta:

```bash
docker-compose up --build
```

Este comando:
- Descarga las imágenes necesarias (Oracle XE, MongoDB)
- Construye las imágenes de los servicios
- Levanta todos los contenedores en el orden correcto
- Configura las dependencias entre servicios

### Paso 4: Esperar a que los servicios estén listos

Los servicios pueden tardar unos minutos en iniciarse, especialmente Oracle Database. Verifica que todos estén corriendo:

```bash
docker-compose ps
```

Deberías ver todos los servicios con estado `Up`:
- `oracle`
- `mongodb`
- `clients`
- `billing`
- `audit`

### Paso 5: Crear las bases de datos en Oracle

Antes de ejecutar las migraciones, es necesario crear los usuarios de base de datos en Oracle. Ejecuta los siguientes comandos:

1. Accede al contenedor de Oracle:

```bash
docker-compose exec oracle bash
```

2. Conéctate a SQL*Plus:

```bash
sqlplus SYSTEM/developmentpass@oracle:1521/xepdb1
```

3. Ejecuta los siguientes comandos SQL para crear los usuarios y otorgar permisos:

```sql
CREATE USER invoice_app_production_db IDENTIFIED BY "productionpass";
CREATE USER invoice_app_development_db IDENTIFIED BY "developmentpass";
CREATE USER invoice_app_test_db IDENTIFIED BY "testpass";

GRANT CONNECT, RESOURCE, DBA TO invoice_app_production_db;
GRANT CONNECT, RESOURCE, DBA TO invoice_app_development_db;
GRANT CONNECT, RESOURCE, DBA TO invoice_app_test_db;

GRANT UNLIMITED TABLESPACE TO invoice_app_production_db;
GRANT UNLIMITED TABLESPACE TO invoice_app_development_db;
GRANT UNLIMITED TABLESPACE TO invoice_app_test_db;
```

4. Sal de SQL*Plus escribiendo `exit` y luego sal del contenedor con `exit` nuevamente.

**Nota:** Asegúrate de que Oracle esté completamente inicializado antes de ejecutar estos comandos. Si encuentras errores de conexión, espera unos minutos y vuelve a intentarlo.

### Paso 6: Ejecutar migraciones de base de datos

Una vez que los servicios estén corriendo, ejecuta las migraciones:

```bash
# Migraciones para Clients Service
docker-compose exec clients rails db:migrate

# Migraciones para Billing Service
docker-compose exec billing rails db:migrate
```

**Nota:** El servicio de auditoría no requiere migraciones ya que usa MongoDB.

### Paso 7: Ejecutar seeds (datos iniciales)

Opcionalmente, puedes ejecutar los seeds para cargar datos iniciales en las bases de datos:

```bash
# Seeds para Clients Service
docker-compose exec clients rails db:seed

# Seeds para Billing Service
docker-compose exec billing rails db:seed
```

### Paso 8: Verificar que los servicios estén funcionando

Prueba los endpoints de health check:

```bash
# Clients Service
curl http://localhost:3000/api/v1/health_check

# Billing Service
curl http://localhost:3001/api/v1/health_check

# Audit Service
curl http://localhost:3002/api/v1/health_check
```

Todos deberían responder con un estado `200 OK`.

## 🧪 Probar la API

### Opción 1: Usando Postman (Recomendado)

Se incluye una colección de Postman con todos los endpoints configurados:

1. Abre Postman
2. Importa el archivo `technical_test_dvp.postman_collection.json`
3. La colección incluye:
   - **Clients service**: Health check, listar clientes, buscar, obtener por ID, crear cliente
   - **Billing service**: Health check, listar facturas, filtros por fecha/cliente/estado, crear factura
   - **Audit service**: Health check, listar logs, obtener logs por recurso

4. Ejecuta las peticiones directamente desde Postman

### Opción 2: Usando cURL

#### Crear un cliente

```bash
curl -X POST http://localhost:3000/api/v1/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "identification": "123456789",
      "address": "Calle 123"
    }
  }'
```

#### Crear una factura

```bash
curl -X POST http://localhost:3001/api/v1/facturas \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "client_id": 1,
      "issue_date": "2024-01-15",
      "due_date": "2024-02-15",
      "subtotal": 1000.00,
      "tax": 190.00,
      "notes": "Servicios de consultoría"
    }
  }'
```

#### Consultar logs de auditoría

```bash
curl http://localhost:3002/api/v1/auditoria
```

## 🛑 Detener los servicios

Para detener todos los servicios:

```bash
docker-compose down
```

Para detener y eliminar los volúmenes (datos de bases de datos):

```bash
docker-compose down -v
```

## 📊 Puertos de los Servicios

| Servicio | Puerto | URL Base |
|----------|--------|----------|
| Clients Service | 3000 | http://localhost:3000 |
| Billing Service | 3001 | http://localhost:3001 |
| Audit Service | 3002 | http://localhost:3002 |
| Oracle Database | 1521 | localhost:1521 |
| MongoDB | 27017 | localhost:27017 |

## 🔧 Comandos Útiles

### Ver logs de un servicio específico

```bash
docker-compose logs -f clients
docker-compose logs -f billing
docker-compose logs -f audit
```

### Reiniciar un servicio específico

```bash
docker-compose restart clients
docker-compose restart billing
docker-compose restart audit
```

### Ejecutar comandos Rails en un servicio

```bash
# Clients Service
docker-compose exec clients rails console
docker-compose exec clients rails db:migrate

# Billing Service
docker-compose exec billing rails console
docker-compose exec billing rails db:migrate
```

### Reconstruir un servicio después de cambios

```bash
docker-compose up --build clients
```

## 📚 Documentación Adicional

Para información detallada de cada servicio, consulta:

- [📖 Clients Service README](./clients_service/README.md)
- [📖 Billing Service README](./billing_service/README.md)
- [📖 Audit Service README](./audit_service/README.md)

## ⚠️ Solución de Problemas

### Los servicios no inician

1. Verifica que los puertos 3000, 3001, 3002, 1521 y 27017 no estén en uso
2. Revisa los logs: `docker-compose logs`
3. Asegúrate de que los archivos `.env` existan en cada servicio

### Error de conexión a Oracle

1. Espera unos minutos después de iniciar los servicios (Oracle tarda en inicializarse)
2. Verifica que el contenedor de Oracle esté corriendo: `docker-compose ps oracle`
3. Revisa los logs de Oracle: `docker-compose logs oracle`

### Error de conexión a MongoDB

1. Verifica que el contenedor de MongoDB esté corriendo: `docker-compose ps mongodb`
2. Revisa los logs: `docker-compose logs mongodb`

### Las migraciones fallan

1. Asegúrate de que Oracle esté completamente inicializado (puede tardar 2-3 minutos)
2. Verifica las variables de entorno en los archivos `.env`
3. Intenta ejecutar las migraciones nuevamente después de unos minutos

## 🎯 Próximos Pasos

1. Importa la colección de Postman para probar todos los endpoints
2. Revisa la documentación individual de cada servicio
3. Explora los endpoints disponibles en cada servicio