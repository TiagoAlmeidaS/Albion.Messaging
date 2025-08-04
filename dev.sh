#!/bin/bash

echo "🔧 Modo Desenvolvimento - Albion Messaging"

# Verificar se o .NET está instalado
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK não encontrado. Por favor, instale o .NET 8 SDK."
    exit 1
fi

# Verificar se o RabbitMQ está rodando
echo "🔍 Verificando se o RabbitMQ está rodando..."
if ! curl -s http://localhost:15672 > /dev/null; then
    echo "❌ RabbitMQ não está rodando na porta 15672."
    echo "💡 Execute primeiro: docker-compose up -d rabbitmq"
    echo "   Ou inicie o ambiente completo: ./start.sh"
    exit 1
fi

echo "✅ RabbitMQ está rodando!"

# Executar o provisionador
echo "🚀 Executando RabbitMQ Provisioner..."
dotnet run --project RabbitMqProvisioner

echo ""
echo "✅ Provisionamento concluído!"
echo "📊 Verifique as exchanges e queues em: http://localhost:15672" 