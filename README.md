# Albion.Messaging

Infraestrutura de mensageria para o Albion usando RabbitMQ com provisionamento automatizado.

## Requisitos

- Docker
- Docker Compose

## Uso Rápido

Para iniciar toda a infraestrutura (RabbitMQ + provisionamento automático):

```bash
./start.sh
```

Ou manualmente:

```bash
docker-compose up --build -d
```

## Estrutura do Projeto

### Serviços Docker

- **rabbitmq**: Broker RabbitMQ com interface de gerenciamento
- **rabbitmq-provisioner**: Aplicação .NET que cria exchanges e queues automaticamente

### Configuração

As exchanges e queues são definidas em `configs/messaging.settings.json`:

```json
{
  "exchanges": [
    { "name": "albion.sniffer", "type": "topic", "durable": true, "autoDelete": false },
    { "name": "albion.fishing", "type": "direct", "durable": true, "autoDelete": false },
    { "name": "albion.events.raw", "type": "fanout", "durable": true, "autoDelete": false }
  ],
  "queues": [
    { "name": "sniffer.raw.packets", "bindingKey": "albion.packet.*", "exchange": "albion.sniffer", "durable": true },
    { "name": "sniffer.events.newcharacter", "bindingKey": "albion.event.newcharacter", "exchange": "albion.sniffer", "durable": true },
    { "name": "fishing.bot.trigger", "bindingKey": "fish.*", "exchange": "albion.fishing", "durable": true }
  ]
}
```

## Acessos

- **RabbitMQ Management**: http://localhost:15672
  - Usuário: `myuser`
  - Senha: `mysecurepassword`
- **AMQP**: localhost:5672

## Comandos Úteis

```bash
# Ver logs do provisionador
docker-compose logs rabbitmq-provisioner

# Ver logs do RabbitMQ
docker-compose logs rabbitmq

# Parar todos os serviços
docker-compose down

# Reiniciar apenas o provisionador
docker-compose restart rabbitmq-provisioner
```

## Desenvolvimento

Para executar o provisionador localmente (sem Docker):

```bash
./dev.sh
```

Ou manualmente:

```bash
dotnet run --project RabbitMqProvisioner
```

**Nota**: Certifique-se de que o RabbitMQ esteja rodando antes de executar o provisionador localmente.

## 🖥️ Configuração em VPS

Para configurar em uma VPS:

```bash
# Configurar ambiente
./setup-vps.sh

# Testar conectividade
./test-rabbitmq.sh

# Executar provisionador
./dev.sh
```

### 🔧 Configuração do Sniffer

Configure seu sniffer para conectar em:
- **Host**: `localhost` (ou IP da VPS)
- **Porta**: `5672`
- **Usuário**: `myuser`
- **Senha**: `mysecurepassword`

### 🚨 Solução de Problemas

Se encontrar erro `BrokerUnreachableException`:

1. **Verifique se o RabbitMQ está rodando**:
   ```bash
   docker-compose ps
   ```

2. **Teste a conectividade**:
   ```bash
   ./test-rabbitmq.sh
   ```

3. **Verifique logs do RabbitMQ**:
   ```bash
   docker-compose logs rabbitmq
   ```

4. **Reinicie o RabbitMQ**:
   ```bash
   docker-compose restart rabbitmq
   ```
