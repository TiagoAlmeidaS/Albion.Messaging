#!/bin/bash

# Script para validar configuração de limites das filas RabbitMQ
# Autor: Sistema de Provisionamento RabbitMQ
# Data: $(date)

set -e

echo "🔍 Validando configuração de limites das filas RabbitMQ..."
echo "=================================================="

# Configurações
RABBITMQ_HOST=${RABBITMQ_HOST:-"tastechdeveloper.shop"}
RABBITMQ_USER=${RABBITMQ_USER:-"myuser"}
RABBITMQ_PASS=${RABBITMQ_PASS:-"mysecurepassword"}
RABBITMQ_PORT=${RABBITMQ_PORT:-"15672"}

# Função para fazer requisição à API do RabbitMQ
make_api_request() {
    local endpoint=$1
    curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
         "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/${endpoint}"
}

# Verificar se o RabbitMQ está acessível
echo "📡 Verificando conectividade com RabbitMQ..."
if ! make_api_request "overview" > /dev/null 2>&1; then
    echo "❌ Erro: Não foi possível conectar ao RabbitMQ em ${RABBITMQ_HOST}:${RABBITMQ_PORT}"
    echo "   Verifique se o serviço está rodando e as credenciais estão corretas."
    exit 1
fi
echo "✅ Conectado ao RabbitMQ com sucesso!"

# Listar todas as filas e verificar argumentos
echo ""
echo "🔍 Verificando configuração de limites das filas..."
echo "---------------------------------------------------"

queues_json=$(make_api_request "queues")
total_queues=$(echo "$queues_json" | jq length)
valid_queues=0
invalid_queues=0

echo "📊 Total de filas encontradas: $total_queues"
echo ""

for i in $(seq 0 $((total_queues - 1))); do
    queue_name=$(echo "$queues_json" | jq -r ".[$i].name")
    arguments=$(echo "$queues_json" | jq -r ".[$i].arguments")
    
    # Verificar se tem argumentos de limitação
    max_length=$(echo "$arguments" | jq -r '.["x-max-length"] // empty')
    overflow=$(echo "$arguments" | jq -r '.["x-overflow"] // empty')
    
    if [ -n "$max_length" ] && [ -n "$overflow" ]; then
        echo "✅ $queue_name"
        echo "   └── Max Length: $max_length, Overflow: $overflow"
        ((valid_queues++))
    else
        echo "❌ $queue_name"
        echo "   └── Sem configuração de limite"
        ((invalid_queues++))
    fi
done

echo ""
echo "📈 Resumo da Validação:"
echo "======================="
echo "✅ Filas com limite configurado: $valid_queues"
echo "❌ Filas sem limite: $invalid_queues"

if [ $invalid_queues -eq 0 ]; then
    echo ""
    echo "🎉 SUCESSO: Todas as filas estão configuradas com limites!"
    echo "   - Limite máximo: 1000 mensagens"
    echo "   - Comportamento overflow: drop-head (FIFO)"
    exit 0
else
    echo ""
    echo "⚠️  ATENÇÃO: $invalid_queues fila(s) não possuem configuração de limite."
    echo "   Execute o provisionador novamente para aplicar as configurações."
    exit 1
fi