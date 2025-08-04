#!/bin/bash

echo "🚀 Iniciando Albion Messaging Infrastructure..."

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Parar containers existentes (se houver)
echo "🛑 Parando containers existentes..."
docker-compose down

# Construir e iniciar os serviços
echo "🔨 Construindo e iniciando serviços..."
docker-compose up --build -d

# Aguardar o RabbitMQ estar pronto
echo "⏳ Aguardando RabbitMQ estar pronto..."
sleep 10

# Verificar status dos serviços
echo "📊 Status dos serviços:"
docker-compose ps

echo ""
echo "✅ Ambiente iniciado com sucesso!"
echo "📋 Serviços disponíveis:"
echo "   - RabbitMQ: http://localhost:15672 (admin: myuser/mysecurepassword)"
echo "   - AMQP: localhost:5672"
echo ""
echo "🔧 Para ver logs do provisionador:"
echo "   docker-compose logs rabbitmq-provisioner"
echo ""
echo "🛑 Para parar: docker-compose down" 