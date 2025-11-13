#!/bin/bash

# Script de prueba del sistema de auditoría
# Asegúrate de que todos los servicios estén corriendo antes de ejecutar

echo "============================================"
echo "PRUEBA DEL SISTEMA DE AUDITORÍA"
echo "============================================"
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLIENTS_URL="http://localhost:3001"
BILLING_URL="http://localhost:3002"
AUDIT_URL="http://localhost:3000"

echo -e "${BLUE}1. Verificando servicios...${NC}"
echo ""

# Verificar Clients Service
echo -n "Clients Service (3001)... "
if curl -s "${CLIENTS_URL}/api/v1/health_check" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}No disponible (puede no tener health_check)${NC}"
fi

# Verificar Billing Service
echo -n "Billing Service (3002)... "
if curl -s "${BILLING_URL}/api/v1/health_check" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}No disponible (puede no tener health_check)${NC}"
fi

# Verificar Audit Service
echo -n "Audit Service (3000)... "
if curl -s "${AUDIT_URL}/api/v1/health_check" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}No disponible (puede no tener health_check)${NC}"
fi

echo ""
echo -e "${BLUE}2. Creando un cliente...${NC}"
echo ""

CLIENT_RESPONSE=$(curl -s -X POST "${CLIENTS_URL}/api/v1/clients" \
  -H "Content-Type: application/json" \
  -d '{
    "client": {
      "name": "Test Audit User",
      "email": "test.audit@example.com",
      "identification": "TEST-'$(date +%s)'",
      "address": "123 Test Street"
    }
  }')

echo "$CLIENT_RESPONSE" | jq '.'

CLIENT_ID=$(echo "$CLIENT_RESPONSE" | jq -r '.data.id')

if [ "$CLIENT_ID" != "null" ] && [ -n "$CLIENT_ID" ]; then
    echo ""
    echo -e "${GREEN}✓ Cliente creado con ID: $CLIENT_ID${NC}"
    
    echo ""
    echo -e "${BLUE}3. Consultando el cliente (genera log de lectura)...${NC}"
    sleep 1
    
    curl -s "${CLIENTS_URL}/api/v1/clients/${CLIENT_ID}" | jq '.'
    
    echo ""
    echo -e "${BLUE}4. Creando una factura...${NC}"
    sleep 1
    
    INVOICE_RESPONSE=$(curl -s -X POST "${BILLING_URL}/api/v1/invoices" \
      -H "Content-Type: application/json" \
      -d '{
        "invoice": {
          "client_id": '${CLIENT_ID}',
          "subtotal": 100.00,
          "tax": 21.00,
          "status": "pending",
          "notes": "Factura de prueba para auditoría"
        }
      }')
    
    echo "$INVOICE_RESPONSE" | jq '.'
    
    INVOICE_ID=$(echo "$INVOICE_RESPONSE" | jq -r '.data.id')
    
    if [ "$INVOICE_ID" != "null" ] && [ -n "$INVOICE_ID" ]; then
        echo ""
        echo -e "${GREEN}✓ Factura creada con ID: $INVOICE_ID${NC}"
        
        echo ""
        echo -e "${BLUE}5. Esperando 3 segundos para procesamiento de auditoría...${NC}"
        sleep 3
        
        echo ""
        echo -e "${BLUE}6. Consultando logs de auditoría del cliente...${NC}"
        echo ""
        
        curl -s "${AUDIT_URL}/api/v1/auditoria/${CLIENT_ID}" | jq '.'
        
        echo ""
        echo -e "${BLUE}7. Consultando logs de auditoría de la factura...${NC}"
        echo ""
        
        curl -s "${AUDIT_URL}/api/v1/auditoria/${INVOICE_ID}" | jq '.'
        
        echo ""
        echo -e "${BLUE}8. Consultando todos los logs recientes de clientes...${NC}"
        echo ""
        
        curl -s "${AUDIT_URL}/api/v1/auditoria?resource_type=client" | jq '.data | .[:3]'
        
        echo ""
        echo -e "${BLUE}9. Consultando todos los logs recientes de facturas...${NC}"
        echo ""
        
        curl -s "${AUDIT_URL}/api/v1/auditoria?resource_type=invoice" | jq '.data | .[:3]'
        
    else
        echo ""
        echo -e "${YELLOW}⚠ No se pudo crear la factura${NC}"
    fi
    
else
    echo ""
    echo -e "${YELLOW}⚠ No se pudo crear el cliente${NC}"
fi

echo ""
echo "============================================"
echo -e "${GREEN}PRUEBA COMPLETADA${NC}"
echo "============================================"
echo ""
echo "Revisa los logs del consumer para ver el procesamiento:"
echo "  tail -f audit_service/log/development.log"
echo ""
echo "Accede a RabbitMQ Management:"
echo "  http://localhost:15672 (guest/guest)"
echo ""

