# 🚀 Inicio Rápido del Sistema de Auditoría

## Estado Actual

✅ RabbitMQ ya está corriendo en `localhost:5672`  
✅ MongoDB ya está corriendo en `localhost:27017`  
✅ PostgreSQL ya está corriendo en `localhost:5432`

## Pasos para iniciar el sistema

### 1. Configurar variables de entorno (opcional)

Los servicios ya funcionarán con los valores por defecto, pero si necesitas personalizar:

```bash
# En cada servicio, crea un archivo .env basado en las variables por defecto
# audit_service/.env
# billing_service/.env  
# clients_service/.env
```

### 2. Preparar las bases de datos

**Clients Service:**
```bash
cd clients_service
bundle install
rails db:create db:migrate
```

**Billing Service:**
```bash
cd billing_service
bundle install
rails db:create db:migrate
```

**Audit Service:**
```bash
cd audit_service
bundle install
# MongoDB no requiere migraciones
```

### 3. Iniciar los servicios

Abre **4 terminales** y ejecuta en cada una:

**Terminal 1 - Clients Service:**
```bash
cd clients_service
rails server -p 3001
```

**Terminal 2 - Billing Service:**
```bash
cd billing_service
rails server -p 3002
```

**Terminal 3 - Audit Service:**
```bash
cd audit_service
rails server -p 3000
```

**Terminal 4 - Audit Consumer:**
```bash
cd audit_service
bundle exec rake audit:consumer
# O alternativamente:
# ./bin/consumer
```

### 4. Probar el sistema

Una vez que todos los servicios estén corriendo, ejecuta el script de prueba:

```bash
./test_audit_system.sh
```

O prueba manualmente:

```bash
# Crear un cliente
curl -X POST http://localhost:3001/api/v1/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "identification": "12345678"
    }
  }'

# Esperar 2-3 segundos para que se procese la auditoría

# Ver los logs de auditoría
curl http://localhost:3000/api/v1/auditoria
```

## Verificación de servicios

### RabbitMQ Management UI
- URL: http://localhost:15672
- Usuario: `guest`
- Contraseña: `guest`

Aquí podrás ver:
- La exchange `audit_events`
- La queue `audit_logs`
- Mensajes siendo procesados en tiempo real

### Endpoints de servicios

**Clients Service (3001):**
- GET http://localhost:3001/api/v1/clients
- POST http://localhost:3001/api/v1/clients
- GET http://localhost:3001/api/v1/clients/:id

**Billing Service (3002):**
- GET http://localhost:3002/api/v1/invoices
- POST http://localhost:3002/api/v1/invoices
- GET http://localhost:3002/api/v1/invoices/:id

**Audit Service (3000):**
- GET http://localhost:3000/api/v1/auditoria
- GET http://localhost:3000/api/v1/auditoria/:resource_id
- GET http://localhost:3000/api/v1/auditoria?resource_type=client
- GET http://localhost:3000/api/v1/auditoria?resource_type=invoice

## Logs del Consumer

Para ver en tiempo real cómo se procesan los eventos de auditoría:

```bash
tail -f audit_service/log/development.log
```

Deberías ver líneas como:
```
Processing audit event: audit.client.create
Audit log saved successfully: 507f1f77bcf86cd799439011
```

## Troubleshooting

### "Bind for 0.0.0.0:5672 failed: port is already allocated"

✅ **Esto es normal** - Ya tienes RabbitMQ corriendo. Solo verifica que esté activo:

```bash
docker ps | grep rabbitmq
```

### Consumer no procesa mensajes

1. Verifica que RabbitMQ esté accesible:
   ```bash
   curl http://localhost:15672
   ```

2. Verifica los logs del consumer:
   ```bash
   tail -f audit_service/log/development.log
   ```

3. Reinicia el consumer (Ctrl+C y volver a iniciar)

### No se crean logs de auditoría

1. Verifica que el consumer esté corriendo
2. Revisa la cola en RabbitMQ Management UI
3. Verifica los logs de la aplicación que publica eventos:
   ```bash
   tail -f billing_service/log/development.log | grep audit
   ```

## ¿Qué hace cada componente?

```
Cliente → Clients/Billing Service → RabbitMQ → Audit Consumer → MongoDB
            (Publica evento)      (Cola)     (Procesa)      (Persiste)
```

1. **Clients/Billing Service**: Cuando se crea, actualiza o consulta un recurso, se publica un evento a RabbitMQ
2. **RabbitMQ**: Recibe y almacena los eventos en la cola `audit_logs`
3. **Audit Consumer**: Consume mensajes de la cola y los procesa
4. **MongoDB**: Almacena los logs de auditoría de forma persistente

## Flujo de ejemplo completo

```bash
# 1. Crear cliente
POST /api/v1/clients
  ↓
# 2. Se guarda en PostgreSQL
  ↓
# 3. Callback after_create del modelo
  ↓
# 4. AuditPublisherService publica a RabbitMQ
  ↓
# 5. Mensaje queda en cola 'audit_logs'
  ↓
# 6. AuditConsumerJob consume el mensaje
  ↓
# 7. Se crea AuditLog en MongoDB
  ↓
# 8. Consulta disponible en GET /api/v1/auditoria
```

---

**📖 Para más detalles, consulta:** [AUDITORIA.md](./AUDITORIA.md)

