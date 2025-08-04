#!/bin/bash

echo "🔍 Testando conectividade do RabbitMQ..."

# Configurar host baseado no ambiente
if [ -n "$VPS_HOST" ]; then
    RABBITMQ_HOST="$VPS_HOST"
    echo "🌐 Usando host VPS: $RABBITMQ_HOST"
else
    # Detectar automaticamente se é VPS ou local
    if curl -s http://tastechdeveloper.shop:15672 >/dev/null 2>&1; then
        RABBITMQ_HOST="tastechdeveloper.shop"
        echo "🌐 Detectado VPS: $RABBITMQ_HOST"
    elif docker-compose ps rabbitmq 2>/dev/null | grep -q "Up"; then
        RABBITMQ_HOST="localhost"
        echo "🐳 Detectado Docker local: $RABBITMQ_HOST"
    elif curl -s http://localhost:15672 >/dev/null 2>&1; then
        RABBITMQ_HOST="localhost"
        echo "💻 Detectado RabbitMQ local: $RABBITMQ_HOST"
    else
        echo "❌ RabbitMQ não encontrado"
        echo "💡 Configure VPS_HOST ou inicie localmente: docker-compose up -d rabbitmq"
        exit 1
    fi
fi

# Testar conectividade AMQP
echo ""
echo "🔌 Testando conectividade AMQP na porta 5672..."
if nc -z $RABBITMQ_HOST 5672 2>/dev/null; then
    echo "✅ Porta 5672 está acessível"
else
    echo "❌ Porta 5672 não está acessível"
    echo "💡 Verifique se o RabbitMQ está rodando em $RABBITMQ_HOST"
    exit 1
fi

# Testar autenticação
echo ""
echo "🔐 Testando autenticação..."
if curl -s -u myuser:mysecurepassword http://$RABBITMQ_HOST:15672/api/overview >/dev/null 2>&1; then
    echo "✅ Autenticação bem-sucedida"
else
    echo "❌ Falha na autenticação"
    echo "💡 Verifique usuário/senha em configs/messaging.settings.json"
    exit 1
fi

# Verificar exchanges e queues existentes
echo ""
echo "📋 Exchanges existentes:"
curl -s -u myuser:mysecurepassword http://$RABBITMQ_HOST:15672/api/exchanges | jq -r '.[].name' 2>/dev/null || echo "Nenhuma exchange encontrada"

echo ""
echo "📋 Queues existentes:"
curl -s -u myuser:mysecurepassword http://$RABBITMQ_HOST:15672/api/queues | jq -r '.[].name' 2>/dev/null || echo "Nenhuma queue encontrada"

echo ""
echo "✅ Teste de conectividade concluído!"
echo "🌐 Interface web: http://$RABBITMQ_HOST:15672"
echo "👤 Usuário: myuser"
echo "🔑 Senha: mysecurepassword"
echo "🔌 AMQP: $RABBITMQ_HOST:5672" 