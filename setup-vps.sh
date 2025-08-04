#!/bin/bash

echo "🚀 Configurando Albion Messaging na VPS..."

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado. Faça logout e login novamente."
    exit 0
fi

# Verificar se o Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não está instalado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado."
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down 2>/dev/null || true

# Iniciar apenas o RabbitMQ
echo "🔧 Iniciando RabbitMQ..."
docker-compose up -d rabbitmq

# Aguardar o RabbitMQ estar pronto
echo "⏳ Aguardando RabbitMQ estar pronto..."
sleep 15

# Testar conectividade
echo "🔍 Testando conectividade..."
./test-rabbitmq.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Configuração concluída com sucesso!"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Execute o provisionador: ./dev.sh"
    echo "2. Configure seu sniffer para usar: localhost:5672"
    echo "3. Credenciais: myuser/mysecurepassword"
    echo ""
    echo "🌐 Interface web: http://localhost:15672"
else
    echo "❌ Falha na configuração. Verifique os logs acima."
    exit 1
fi 