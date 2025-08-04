# 🌐 Configuração VPS - Albion Messaging

## ✅ Status Atual

**VPS**: `tastechdeveloper.shop`  
**Status**: ✅ Funcionando  
**Interface Web**: http://tastechdeveloper.shop:15672  
**AMQP**: tastechdeveloper.shop:5672  

## 📋 Exchanges Criadas

- ✅ `albion.sniffer` (topic)
- ✅ `albion.fishing` (direct)  
- ✅ `albion.events.raw` (fanout)

## 📋 Queues Criadas

- ✅ `sniffer.raw.packets` → `albion.sniffer` (albion.packet.*)
- ✅ `sniffer.events.newcharacter` → `albion.sniffer` (albion.event.newcharacter)
- ✅ `sniffer.events.*` → `albion.sniffer` (albion.event.*)
- ✅ `fishing.bot.trigger` → `albion.fishing` (fish.*)

## 🔧 Configuração do Sniffer

Configure seu sniffer para conectar em:

```json
{
  "host": "tastechdeveloper.shop",
  "port": 5672,
  "username": "myuser",
  "password": "mysecurepassword",
  "virtualHost": "/"
}
```

## 🛠️ Comandos Úteis

### Testar Conectividade
```bash
./test-vps.sh
```

### Executar Provisionador
```bash
./dev.sh
```

### Verificar Status
```bash
curl -s -u myuser:mysecurepassword http://tastechdeveloper.shop:15672/api/overview
```

### Listar Exchanges
```bash
curl -s -u myuser:mysecurepassword http://tastechdeveloper.shop:15672/api/exchanges
```

### Listar Queues
```bash
curl -s -u myuser:mysecurepassword http://tastechdeveloper.shop:15672/api/queues
```

## 🚨 Solução de Problemas

### Erro: BrokerUnreachableException

1. **Verificar conectividade**:
   ```bash
   ./test-vps.sh
   ```

2. **Verificar se a VPS está online**:
   ```bash
   ping tastechdeveloper.shop
   ```

3. **Verificar portas**:
   ```bash
   nc -z tastechdeveloper.shop 5672
   nc -z tastechdeveloper.shop 15672
   ```

### Erro: Connection Refused

- Verificar se o RabbitMQ está rodando na VPS
- Verificar firewall/iptables
- Verificar configuração de rede

## 📊 Monitoramento

- **Interface Web**: http://tastechdeveloper.shop:15672
- **Usuário**: myuser
- **Senha**: mysecurepassword

## 🔄 Atualizações

Para atualizar a configuração:

1. Edite `configs/messaging.settings.json`
2. Execute: `./dev.sh`
3. Verifique: `./test-vps.sh` 