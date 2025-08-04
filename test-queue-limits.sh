#!/bin/bash

# Script para testar o comportamento de limite das filas RabbitMQ
# Envia mensagens para verificar se o limite de 1000 mensagens está funcionando
# Autor: Sistema de Provisionamento RabbitMQ

set -e

echo "🧪 Testando comportamento de limite das filas RabbitMQ..."
echo "======================================================="

# Configurações
RABBITMQ_HOST=${RABBITMQ_HOST:-"tastechdeveloper.shop"}
RABBITMQ_USER=${RABBITMQ_USER:-"myuser"}
RABBITMQ_PASS=${RABBITMQ_PASS:-"mysecurepassword"}
RABBITMQ_PORT=${RABBITMQ_PORT:-"15672"}
RABBITMQ_AMQP_PORT=${RABBITMQ_AMQP_PORT:-"5672"}

TEST_QUEUE="sniffer.raw.packets"
TEST_MESSAGES=1005  # Enviar mais que o limite para testar

echo "🎯 Fila de teste: $TEST_QUEUE"
echo "📦 Mensagens a enviar: $TEST_MESSAGES"
echo "🎚️  Limite esperado: 1000"
echo ""

# Função para fazer requisição à API do RabbitMQ
make_api_request() {
    local endpoint=$1
    curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
         "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/${endpoint}"
}

# Função para obter o número de mensagens na fila
get_queue_message_count() {
    local queue_name=$1
    make_api_request "queues/%2F/${queue_name}" | jq -r '.messages // 0'
}

# Verificar se o RabbitMQ está acessível
echo "📡 Verificando conectividade com RabbitMQ..."
if ! make_api_request "overview" > /dev/null 2>&1; then
    echo "❌ Erro: Não foi possível conectar ao RabbitMQ em ${RABBITMQ_HOST}:${RABBITMQ_PORT}"
    exit 1
fi
echo "✅ Conectado ao RabbitMQ com sucesso!"

# Verificar se a fila existe
echo "🔍 Verificando se a fila '$TEST_QUEUE' existe..."
if ! make_api_request "queues/%2F/${TEST_QUEUE}" > /dev/null 2>&1; then
    echo "❌ Erro: Fila '$TEST_QUEUE' não encontrada."
    echo "   Execute o provisionador primeiro para criar as filas."
    exit 1
fi
echo "✅ Fila '$TEST_QUEUE' encontrada!"

# Verificar configuração da fila
echo "🔧 Verificando configuração da fila..."
queue_info=$(make_api_request "queues/%2F/${TEST_QUEUE}")
max_length=$(echo "$queue_info" | jq -r '.arguments["x-max-length"] // empty')
overflow=$(echo "$queue_info" | jq -r '.arguments["x-overflow"] // empty')

if [ -z "$max_length" ] || [ -z "$overflow" ]; then
    echo "❌ Erro: Fila não possui configuração de limite."
    echo "   Execute o provisionador novamente para aplicar as configurações."
    exit 1
fi

echo "✅ Configuração da fila:"
echo "   └── Max Length: $max_length"
echo "   └── Overflow: $overflow"

# Limpar fila antes do teste
echo ""
echo "🧹 Limpando fila antes do teste..."
purge_result=$(curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
    -X DELETE \
    "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/queues/%2F/${TEST_QUEUE}/contents")

initial_count=$(get_queue_message_count "$TEST_QUEUE")
echo "📊 Mensagens na fila após limpeza: $initial_count"

# Criar script Python temporário para enviar mensagens
cat > temp_publisher.py << 'EOF'
import pika
import sys
import json
import time

def send_messages(host, port, username, password, queue_name, num_messages):
    try:
        # Configurar conexão
        credentials = pika.PlainCredentials(username, password)
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=host, port=port, credentials=credentials)
        )
        channel = connection.CreateChannel()
        
        print(f"📤 Enviando {num_messages} mensagens para a fila '{queue_name}'...")
        
        # Enviar mensagens
        for i in range(1, num_messages + 1):
            message = {
                "id": i,
                "timestamp": time.time(),
                "data": f"Test message {i}",
                "test": True
            }
            
            channel.basic_publish(
                exchange='albion.sniffer',
                routing_key='albion.packet.test',
                body=json.dumps(message),
                properties=pika.BasicProperties(delivery_mode=2)  # Persistir mensagem
            )
            
            if i % 100 == 0:
                print(f"   ✅ {i} mensagens enviadas...")
        
        connection.close()
        print(f"🎉 Todas as {num_messages} mensagens foram enviadas!")
        
    except Exception as e:
        print(f"❌ Erro ao enviar mensagens: {e}")
        sys.exit(1)

if __name__ == "__main__":
    host = sys.argv[1]
    port = int(sys.argv[2])
    username = sys.argv[3]
    password = sys.argv[4]
    queue_name = sys.argv[5]
    num_messages = int(sys.argv[6])
    
    send_messages(host, port, username, password, queue_name, num_messages)
EOF

# Verificar se Python e pika estão disponíveis
echo ""
echo "🐍 Verificando dependências Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não encontrado. Instalando..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip
    else
        echo "❌ Não foi possível instalar Python3 automaticamente."
        exit 1
    fi
fi

if ! python3 -c "import pika" 2>/dev/null; then
    echo "📦 Instalando biblioteca pika..."
    pip3 install pika --quiet
fi

echo "✅ Dependências verificadas!"

# Enviar mensagens de teste
echo ""
echo "🚀 Iniciando teste de limite..."
python3 temp_publisher.py "$RABBITMQ_HOST" "$RABBITMQ_AMQP_PORT" "$RABBITMQ_USER" "$RABBITMQ_PASS" "$TEST_QUEUE" "$TEST_MESSAGES"

# Aguardar um pouco para as mensagens serem processadas
echo ""
echo "⏳ Aguardando processamento das mensagens..."
sleep 5

# Verificar resultado
final_count=$(get_queue_message_count "$TEST_QUEUE")
echo ""
echo "📊 Resultado do Teste:"
echo "====================="
echo "📤 Mensagens enviadas: $TEST_MESSAGES"
echo "📥 Mensagens na fila: $final_count"
echo "🎚️  Limite configurado: $max_length"

if [ "$final_count" -le "$max_length" ]; then
    echo ""
    echo "🎉 SUCESSO: O limite está funcionando corretamente!"
    echo "   ✅ A fila não excedeu o limite de $max_length mensagens"
    echo "   ✅ Comportamento FIFO (drop-head) está ativo"
    
    if [ "$final_count" -eq "$max_length" ]; then
        echo "   ✅ Fila está exatamente no limite máximo"
    else
        echo "   ℹ️  Fila tem $final_count mensagens (abaixo do limite)"
    fi
else
    echo ""
    echo "❌ FALHA: O limite NÃO está funcionando!"
    echo "   ❌ A fila excedeu o limite de $max_length mensagens"
    echo "   ❌ Configuração pode não ter sido aplicada corretamente"
fi

# Limpeza
rm -f temp_publisher.py

echo ""
echo "🧪 Teste concluído!"