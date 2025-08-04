# 🚀 Configuração de Limites de Fila RabbitMQ

Este documento descreve a implementação de limites máximos de mensagens para todas as filas do RabbitMQ no projeto Albion Sniffer.

## 📋 Resumo da Implementação

### ✅ O que foi implementado:

- **Limite máximo**: 1000 mensagens por fila
- **Comportamento overflow**: `drop-head` (FIFO - descarta mensagens mais antigas)
- **Aplicação universal**: Todas as 28 filas configuradas
- **Persistência**: Configuração aplicada automaticamente ao provisionar

### 🔧 Arquivos Modificados

1. **`RabbitMqProvisioner/QueueConfig.cs`**
   - Adicionado suporte a `MaxLength` e `OverflowBehavior`
   - Método `GetArguments()` para gerar argumentos RabbitMQ

2. **`RabbitMqProvisioner/Program.cs`**
   - Aplicação dos argumentos na declaração das filas
   - Log informativo com detalhes dos limites

3. **`configs/messaging.settings.json`**
   - Todas as filas configuradas com `maxLength: 1000`
   - Comportamento `overflowBehavior: "drop-head"`

## 🎯 Filas Configuradas

Todas as 28 filas do sistema agora possuem limite de 1000 mensagens:

### 📦 Filas de Sniffer
- `sniffer.raw.packets`
- `sniffer.events.newcharacter`
- `sniffer.events.*`

### 🗺️ Filas de Clusters
- `clusters.change`
- `clusters.loadobjects`
- `clusters.mistsplayer`

### 👥 Filas de Players
- `players.newcharacter`
- `players.equipment`
- `players.health`
- `players.regeneration`
- `players.mounted`
- `players.move`
- `players.flagging`

### 👹 Filas de Mobs
- `mobs.new`
- `mobs.state`

### 🌿 Filas de Resources
- `resources.new`
- `resources.list`
- `resources.state`

### 🏰 Outras Filas
- `dungeons.new`
- `fishing.zone`
- `fishing.bot.trigger`
- `wisps.new`
- `wisps.gate`
- `chests.new`
- `sync.keys`
- `objects.leave`
- `operations.join`
- `operations.move`

## 🚀 Como Usar

### 1. Aplicar Configuração

Execute o provisionador para aplicar as configurações:

```bash
# Via Docker Compose
docker-compose up rabbitmq-provisioner

# Ou localmente
cd RabbitMqProvisioner
dotnet run
```

### 2. Validar Configuração

Use o script de validação para verificar se todas as filas estão configuradas:

```bash
./validate-queue-limits.sh
```

**Saída esperada:**
```
🔍 Validando configuração de limites das filas RabbitMQ...
==================================================
📡 Verificando conectividade com RabbitMQ...
✅ Conectado ao RabbitMQ com sucesso!

🔍 Verificando configuração de limites das filas...
---------------------------------------------------
📊 Total de filas encontradas: 28

✅ sniffer.raw.packets
   └── Max Length: 1000, Overflow: drop-head
✅ clusters.change
   └── Max Length: 1000, Overflow: drop-head
[... todas as filas ...]

📈 Resumo da Validação:
=======================
✅ Filas com limite configurado: 28
❌ Filas sem limite: 0

🎉 SUCESSO: Todas as filas estão configuradas com limites!
   - Limite máximo: 1000 mensagens
   - Comportamento overflow: drop-head (FIFO)
```

### 3. Testar Comportamento

Execute o teste de comportamento para verificar se o limite está funcionando:

```bash
./test-queue-limits.sh
```

Este script:
- Envia 1005 mensagens para uma fila de teste
- Verifica se apenas 1000 mensagens ficam na fila
- Confirma que as mensagens mais antigas foram descartadas

## ⚙️ Configuração Técnica

### Argumentos RabbitMQ Aplicados

```json
{
  "x-max-length": 1000,
  "x-overflow": "drop-head"
}
```

### Comportamentos de Overflow Disponíveis

- **`drop-head`** (FIFO): Remove mensagens mais antigas ✅ **(Implementado)**
- **`reject-publish`**: Rejeita novas mensagens
- **`reject-publish-dlx`**: Rejeita e envia para Dead Letter Exchange

### Exemplo de Configuração no JSON

```json
{
  "name": "sniffer.raw.packets",
  "bindingKey": "albion.packet.*",
  "exchange": "albion.sniffer",
  "durable": true,
  "maxLength": 1000,
  "overflowBehavior": "drop-head"
}
```

## 🔍 Monitoramento

### Via RabbitMQ Management UI

1. Acesse: `http://tastechdeveloper.shop:15672`
2. Login: `myuser` / `mysecurepassword`
3. Vá em **Queues**
4. Verifique a coluna **Arguments** para cada fila

### Via API REST

```bash
curl -u myuser:mysecurepassword \
  "http://tastechdeveloper.shop:15672/api/queues" | \
  jq '.[] | {name: .name, arguments: .arguments}'
```

### Via CLI (se tiver acesso ao container)

```bash
rabbitmqctl list_queues name arguments
```

## 🚨 Troubleshooting

### Problema: Filas sem limite após provisionamento

**Solução:**
1. Deletar filas existentes via Management UI
2. Executar provisionador novamente
3. Verificar com script de validação

### Problema: Limite não está funcionando

**Possíveis causas:**
- Filas foram criadas antes da configuração
- Conexão com RabbitMQ falhou durante provisionamento
- Configuração JSON inválida

**Solução:**
1. Executar `./validate-queue-limits.sh`
2. Se necessário, recriar filas via Management UI
3. Executar provisionador novamente

### Problema: Script de teste falha

**Verificar:**
- Python3 e pip estão instalados
- Biblioteca `pika` está disponível
- Conectividade com RabbitMQ na porta 5672

## 📊 Benefícios da Implementação

### ✅ Controle de Memória
- Previne acúmulo excessivo de mensagens
- Limita uso de RAM do RabbitMQ
- Evita degradação de performance

### ✅ Comportamento Previsível
- FIFO garante processamento das mensagens mais recentes
- Descarte automático de mensagens antigas
- Sem intervenção manual necessária

### ✅ Configuração Centralizada
- Todas as filas seguem o mesmo padrão
- Fácil manutenção e ajustes
- Documentação clara dos limites

### ✅ Monitoramento Simplificado
- Scripts de validação automatizados
- Testes de comportamento incluídos
- Visibilidade via Management UI

## 🔄 Ajustes Futuros

Para modificar os limites, edite o arquivo `configs/messaging.settings.json`:

```json
{
  "maxLength": 2000,        // Novo limite
  "overflowBehavior": "drop-head"  // Manter FIFO
}
```

Em seguida, execute o provisionador novamente.

---

**✅ Implementação concluída com sucesso!**

Todas as 28 filas do sistema agora possuem limite de 1000 mensagens com comportamento FIFO (drop-head).