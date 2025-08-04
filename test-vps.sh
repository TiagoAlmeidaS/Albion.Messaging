#!/bin/bash

echo "🌐 Testando conectividade da VPS RabbitMQ..."

# Configurar host da VPS
VPS_HOST="tastechdeveloper.shop"
export VPS_HOST

echo "🔍 Testando conectividade com $VPS_HOST..."

# Testar conectividade HTTP (interface web)
echo ""
echo "📊 Testando interface web..."
if curl -s http://$VPS_HOST:15672 >/dev/null 2>&1; then
    echo "✅ Interface web acessível: http://$VPS_HOST:15672"
else
    echo "❌ Interface web não acessível"
    exit 1
fi

# Testar conectividade AMQP
echo ""
echo "🔌 Testando conectividade AMQP..."
if nc -z $VPS_HOST 5672 2>/dev/null; then
    echo "✅ Porta AMQP 5672 acessível"
else
    echo "❌ Porta AMQP 5672 não acessível"
    exit 1
fi

# Testar autenticação
echo ""
echo "🔐 Testando autenticação..."
if curl -s -u myuser:mysecurepassword http://$VPS_HOST:15672/api/overview >/dev/null 2>&1; then
    echo "✅ Autenticação bem-sucedida"
else
    echo "❌ Falha na autenticação"
    echo "💡 Verifique usuário/senha"
    exit 1
fi

# Verificar status do RabbitMQ
echo ""
echo "📊 Status do RabbitMQ:"
OVERVIEW=$(curl -s -u myuser:mysecurepassword http://$VPS_HOST:15672/api/overview)
if [ $? -eq 0 ]; then
    echo "✅ RabbitMQ está funcionando"
    echo "📈 Versão: $(echo $OVERVIEW | jq -r '.rabbitmq_version' 2>/dev/null || echo 'N/A')"
    echo "🔄 Status: $(echo $OVERVIEW | jq -r '.status' 2>/dev/null || echo 'N/A')"
else
    echo "❌ Não foi possível obter status"
fi

# Verificar exchanges e queues
echo ""
echo "📋 Exchanges existentes:"
curl -s -u myuser:mysecurepassword http://$VPS_HOST:15672/api/exchanges | jq -r '.[].name' 2>/dev/null | head -10 || echo "Nenhuma exchange encontrada"

echo ""
echo "📋 Queues existentes:"
curl -s -u myuser:mysecurepassword http://$VPS_HOST:15672/api/queues | jq -r '.[].name' 2>/dev/null | head -10 || echo "Nenhuma queue encontrada"

echo ""
echo "✅ Teste da VPS concluído!"
echo "🌐 Interface web: http://$VPS_HOST:15672"
echo "🔌 AMQP: $VPS_HOST:5672"
echo "👤 Usuário: myuser"
echo "🔑 Senha: mysecurepassword" 