#!/bin/bash

echo "🔧 Modo Desenvolvimento - Albion Messaging"

# Verificar se o .NET está instalado
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK não encontrado. Por favor, instale o .NET 8 SDK."
    exit 1
fi

# Verificar se está conectando na VPS ou localmente
if curl -s http://tastechdeveloper.shop:15672 >/dev/null 2>&1; then
    echo "🌐 Detectado VPS RabbitMQ: tastechdeveloper.shop"
    RABBITMQ_HOST="tastechdeveloper.shop"
elif curl -s http://localhost:15672 >/dev/null 2>&1; then
    echo "💻 Detectado RabbitMQ local: localhost"
    RABBITMQ_HOST="localhost"
else
    echo "❌ RabbitMQ não está acessível."
    echo "💡 Verifique se está rodando em:"
    echo "   - Local: docker-compose up -d rabbitmq"
    echo "   - VPS: http://tastechdeveloper.shop:15672"
    exit 1
fi

echo "✅ RabbitMQ está rodando em $RABBITMQ_HOST!"

# Executar o provisionador
echo "🚀 Executando RabbitMQ Provisioner..."
dotnet run --project RabbitMqProvisioner

echo ""
echo "✅ Provisionamento concluído!"
echo "📊 Verifique as exchanges e queues em: http://$RABBITMQ_HOST:15672" 