# 🎯 MAPEAMENTO COMPLETO DE EVENTOS ALBION ONLINE PARA RABBITMQ

## 📋 **RESUMO EXECUTIVO**

Este documento mapeia todos os **23 tipos de eventos** capturados pelo Albion Online Sniffer e enviados para o RabbitMQ através do sistema de mensageria.

### 🔧 **Configuração do Sistema**
- **Exchange Principal**: `albion.sniffer` (topic)
- **Pattern de Topics**: `albion.event.<domínio>.<ação>[.<subação>]` (hierárquico)
- **Formato da Mensagem**: JSON com metadados e dados do evento
- **Frequência**: Tempo real conforme pacotes capturados

---

## 🏗️ **ESTRUTURA DE EXCHANGES**

### **Exchanges Principais**
1. **`albion.sniffer`** - Exchange principal para todos os eventos
2. **`albion.fishing`** - Exchange específico para eventos de pesca
3. **`albion.events.raw`** - Exchange para pacotes brutos (fanout)
4. **`albion.clusters`** - Exchange para eventos de clusters
5. **`albion.players`** - Exchange para eventos de jogadores
6. **`albion.mobs`** - Exchange para eventos de mobs
7. **`albion.resources`** - Exchange para eventos de recursos
8. **`albion.dungeons`** - Exchange para eventos de dungeons
9. **`albion.wisps`** - Exchange para eventos de wisps/portais
10. **`albion.chests`** - Exchange para eventos de baús
11. **`albion.operations`** - Exchange para eventos de operações

---

## 📊 **MAPEAMENTO DETALHADO DOS EVENTOS**

### 🗺️ **1. EVENTOS DE CLUSTERS E LOCALIZAÇÃO**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `ClusterChangedV1` | `albion.event.cluster.changed` | `clusters.change` | Mudança de cluster/localização |
| `ClusterObjectsLoadedV1` | `albion.event.cluster.objects.loaded` | `clusters.loadobjects` | Carregamento de objetivos do cluster |
| `MistsPlayerJoinedV1` | `albion.event.mists.player.joined` | `clusters.mistsplayer` | Jogador entrando nos Mists |

### 👤 **2. EVENTOS DE JOGADORES**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `PlayerJoinedV1` | `albion.event.player.joined` | `players.newcharacter` | Novo jogador detectado |
| `EquipmentChangedV1` | `albion.event.player.equipment.changed` | `players.equipment` | Mudança de equipamento |
| `HealthUpdatedV1` | `albion.event.player.health.updated` | `players.health` | Atualização de vida |
| `RegenerationChangedV1` | `albion.event.player.regeneration.changed` | `players.regeneration` | Mudança na regeneração |
| `MountedStateChangedV1` | `albion.event.player.mounted.changed` | `players.mounted` | Montou/desmontou |
| `PlayerMovedV1` | `albion.event.player.moved` | `players.move` | Movimento de jogadores |
| `FlaggingFinishedV1` | `albion.event.player.flagging.finished` | `players.flagging` | Mudança de facção |

### 🐉 **3. EVENTOS DE MOBS**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `MobSpawnedV1` | `albion.event.mob.spawned` | `mobs.new` | Novo mob detectado |
| `MobStateChangedV1` | `albion.event.mob.state.changed` | `mobs.state` | Mudança de estado do mob |

### 🌿 **4. EVENTOS DE RECURSOS (HARVESTABLES)**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `HarvestableFoundV1` | `albion.event.harvestable.found` | `resources.new` | Novo recurso detectado |
| `HarvestablesListFoundV1` | `albion.event.harvestable.list.found` | `resources.list` | Lista de recursos |
| `HarvestableStateChangedV1` | `albion.event.harvestable.state.changed` | `resources.state` | Mudança de estado do recurso |

### 🏰 **5. EVENTOS DE DUNGEONS**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `DungeonFoundV1` | `albion.event.world.dungeon.found` | `dungeons.new` | Nova dungeon detectada |

### 🎣 **6. EVENTOS DE PESCA**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `FishingZoneFoundV1` | `albion.event.world.fishing.zone.found` | `fishing.zone` | Nova zona de pesca |
| `fish.*` | `fish.*` | `fishing.bot.trigger` | Triggers para bot de pesca |

### 🌟 **7. EVENTOS DE WISPS (PORTAIS)**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `GatedWispFoundV1` | `albion.event.world.gated.wisp.found` | `wisps.new` | Novo wisp de portal |
| `WispGateOpenedV1` | `albion.event.world.wisp.gate.opened` | `wisps.gate` | Portal de wisp aberto |

### 📦 **8. EVENTOS DE BAÚS**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `LootChestFoundV1` | `albion.event.world.loot.chest.found` | `chests.new` | Novo baú de loot |

### 🔄 **9. EVENTOS DE SINCRONIZAÇÃO**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `KeySyncV1` | `albion.event.cluster.key.sync` | `sync.keys` | Sincronização de chave XOR |

### 🚪 **10. EVENTOS DE SAÍDA**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `EntityLeftV1` | `albion.event.player.left` | `objects.leave` | Jogador/mob saiu do radar |

### ⚙️ **11. EVENTOS DE OPERAÇÕES**

| Evento | Topic | Queue | Descrição |
|--------|-------|-------|-----------|
| `JoinResponseOperation` | `albion.event.joinresponse` | `operations.join` | Resposta de entrada no servidor |
| `PlayerMoveRequestV1` | `albion.event.player.move.request` | `operations.move` | Requisição de movimento |

---

## 🔄 **FLUXO DE PROCESSAMENTO**

```
1. Captura de Pacote → PacketCaptureService
2. Deserialização → Protocol16Deserializer  
3. Processamento → Handler específico
4. Atualização de Estado → Handlers de GameObjects
5. Dispatch → EventDispatcher
6. Publicação → RabbitMQ Publisher
7. Topic → albion.event.<domínio>.<ação>[.<subação>]
```

---

## 📈 **ESTATÍSTICAS**

- **Total de Eventos**: 23 tipos diferentes
- **Categorias**: 11 categorias principais
- **Exchanges**: 11 exchanges organizados por categoria
- **Queues**: 35 queues específicas + 2 catch-all
- **Frequência**: Tempo real conforme pacotes capturados
- **Formato**: JSON com metadados e dados do evento

---

## 🎯 **EXEMPLOS DE USO**

### **Consumindo Eventos Específicos**
```javascript
// Consumir apenas eventos de novos jogadores
channel.bindQueue('players.newcharacter', 'albion.sniffer', 'albion.event.newcharacterevent');

// Consumir todos os eventos de jogadores
channel.bindQueue('players.*', 'albion.sniffer', 'albion.event.*');

// Consumir eventos de pesca para bot
channel.bindQueue('fishing.bot.trigger', 'albion.fishing', 'fish.*');
```

### **Filtros por Categoria**
- **Jogadores**: `albion.event.player.*`
- **Recursos**: `albion.event.harvestable.*`
- **Mobs**: `albion.event.mob.*`
- **Clusters**: `albion.event.cluster.*`

---

## 🔧 **CONFIGURAÇÃO DE QUEUES**

### **Queues Específicas por Categoria**
- **Clusters**: `clusters.change`, `clusters.loadobjects`, `clusters.mistsplayer`
- **Players**: `players.newcharacter`, `players.equipment`, `players.health`, etc.
- **Mobs**: `mobs.new`, `mobs.state`
- **Resources**: `resources.new`, `resources.list`, `resources.state`
- **Dungeons**: `dungeons.new`
- **Fishing**: `fishing.zone`, `fishing.bot.trigger`
- **Wisps**: `wisps.new`, `wisps.gate`
- **Chests**: `chests.new`
- **Sync**: `sync.keys`
- **Objects**: `objects.leave`
- **Operations**: `operations.join`, `operations.move`

### **Queues Catch-All**
- `sniffer.events.newcharacter` - Todos os eventos de novos personagens
- `sniffer.events.*` - Todos os eventos (wildcard)

---

## 📝 **NOTAS IMPORTANTES**

1. **Durabilidade**: Todas as queues são duráveis para persistir mensagens
2. **AutoDelete**: False para manter queues mesmo sem consumidores
3. **Binding Keys**: Seguem o padrão `albion.event.<domínio>.<ação>[.<subação>]`
4. **Exchange Type**: Topic para permitir routing flexível
5. **Formato**: JSON com timestamp e dados estruturados

---

## 🚀 **PRÓXIMOS PASSOS**

1. **Implementar Consumers**: Criar consumidores específicos para cada categoria
2. **Monitoramento**: Implementar métricas de throughput por evento
3. **Alertas**: Configurar alertas para eventos críticos
4. **Retenção**: Configurar TTL para mensagens antigas
5. **Escalabilidade**: Implementar clustering para alta disponibilidade 