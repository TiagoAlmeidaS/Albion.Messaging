#!/usr/bin/env python3
"""
Script de teste para validar o mapeamento completo de eventos Albion Online para RabbitMQ
"""

import json
import sys
from typing import Dict, List, Set

# Lista de eventos V1 com tópicos hierárquicos
ALBION_EVENTS = {
    # Clusters e Localização
    "ClusterChangedV1": "albion.event.cluster.changed",
    "ClusterObjectsLoadedV1": "albion.event.cluster.objects.loaded",
    "MistsPlayerJoinedV1": "albion.event.mists.player.joined",

    # Jogadores
    "PlayerJoinedV1": "albion.event.player.joined",
    "EquipmentChangedV1": "albion.event.player.equipment.changed",
    "HealthUpdatedV1": "albion.event.player.health.updated",
    "RegenerationChangedV1": "albion.event.player.regeneration.changed",
    "MountedStateChangedV1": "albion.event.player.mounted.changed",
    "PlayerMovedV1": "albion.event.player.moved",
    "FlaggingFinishedV1": "albion.event.player.flagging.finished",

    # Mobs
    "MobSpawnedV1": "albion.event.mob.spawned",
    "MobStateChangedV1": "albion.event.mob.state.changed",

    # Recursos
    "HarvestableFoundV1": "albion.event.harvestable.found",
    "HarvestablesListFoundV1": "albion.event.harvestable.list.found",
    "HarvestableStateChangedV1": "albion.event.harvestable.state.changed",

    # Dungeons
    "DungeonFoundV1": "albion.event.world.dungeon.found",

    # Pesca
    "FishingZoneFoundV1": "albion.event.world.fishing.zone.found",

    # Wisps
    "GatedWispFoundV1": "albion.event.world.gated.wisp.found",
    "WispGateOpenedV1": "albion.event.world.wisp.gate.opened",

    # Baús
    "LootChestFoundV1": "albion.event.world.loot.chest.found",

    # Sincronização
    "KeySyncV1": "albion.event.cluster.key.sync",

    # Saída
    "EntityLeftV1": "albion.event.player.left",

    # Operações
    "JoinResponseOperation": "albion.event.joinresponse",
    "PlayerMoveRequestV1": "albion.event.player.move.request",
}

def load_config(filename: str) -> Dict:
    """Carrega arquivo de configuração JSON"""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Arquivo {filename} não encontrado")
        return {}
    except json.JSONDecodeError as e:
        print(f"❌ Erro ao decodificar JSON em {filename}: {e}")
        return {}

def validate_exchanges(config: Dict) -> bool:
    """Valida se todos os exchanges necessários estão configurados"""
    print("🔍 Validando exchanges...")
    
    required_exchanges = {
        "albion.sniffer",
        "albion.fishing", 
        "albion.events.raw",
        "albion.clusters",
        "albion.players",
        "albion.mobs",
        "albion.resources",
        "albion.dungeons",
        "albion.wisps",
        "albion.chests",
        "albion.operations"
    }
    
    configured_exchanges = {ex["name"] for ex in config.get("exchanges", [])}
    missing_exchanges = required_exchanges - configured_exchanges
    
    if missing_exchanges:
        print(f"❌ Exchanges faltando: {missing_exchanges}")
        return False
    
    print(f"✅ Todos os {len(required_exchanges)} exchanges estão configurados")
    return True

def validate_queues(config: Dict) -> bool:
    """Valida se todas as queues necessárias estão configuradas"""
    print("🔍 Validando queues...")
    
    # Queues específicas por evento
    required_queues = {
        "clusters.change": "albion.event.cluster.changed",
        "clusters.loadobjects": "albion.event.cluster.objects.loaded",
        "clusters.mistsplayer": "albion.event.mists.player.joined",
        "players.newcharacter": "albion.event.player.joined",
        "players.equipment": "albion.event.player.equipment.changed",
        "players.health": "albion.event.player.health.updated",
        "players.regeneration": "albion.event.player.regeneration.changed",
        "players.mounted": "albion.event.player.mounted.changed",
        "players.move": "albion.event.player.moved",
        "players.flagging": "albion.event.player.flagging.finished",
        "mobs.new": "albion.event.mob.spawned",
        "mobs.state": "albion.event.mob.state.changed",
        "resources.new": "albion.event.harvestable.found",
        "resources.list": "albion.event.harvestable.list.found",
        "resources.state": "albion.event.harvestable.state.changed",
        "dungeons.new": "albion.event.world.dungeon.found",
        "fishing.zone": "albion.event.world.fishing.zone.found",
        "fishing.bot.trigger": "fish.*",
        "wisps.new": "albion.event.world.gated.wisp.found",
        "wisps.gate": "albion.event.world.wisp.gate.opened",
        "chests.new": "albion.event.world.loot.chest.found",
        "sync.keys": "albion.event.cluster.key.sync",
        "objects.leave": "albion.event.player.left",
        "operations.join": "albion.event.joinresponse",
        "operations.move": "albion.event.player.move.request",
        "sniffer.raw.packets": "albion.packet.*",
        "sniffer.events.newcharacter": "albion.event.player.joined",
        "sniffer.events.*": "albion.event.*"
    }
    
    configured_queues = {}
    for queue in config.get("queues", []):
        configured_queues[queue["name"]] = queue["bindingKey"]
    
    missing_queues = set(required_queues.keys()) - set(configured_queues.keys())
    
    if missing_queues:
        print(f"❌ Queues faltando: {missing_queues}")
        return False
    
    # Validar binding keys
    binding_errors = []
    for queue_name, expected_binding in required_queues.items():
        if queue_name in configured_queues:
            actual_binding = configured_queues[queue_name]
            if actual_binding != expected_binding:
                binding_errors.append(f"{queue_name}: esperado '{expected_binding}', encontrado '{actual_binding}'")
    
    if binding_errors:
        print("❌ Erros de binding keys:")
        for error in binding_errors:
            print(f"  - {error}")
        return False
    
    print(f"✅ Todas as {len(required_queues)} queues estão configuradas corretamente")
    return True

def validate_event_coverage(config: Dict) -> bool:
    """Valida se todos os eventos estão cobertos pelas queues"""
    print("🔍 Validando cobertura de eventos...")
    
    # Extrair binding keys das queues configuradas
    binding_keys = set()
    for queue in config.get("queues", []):
        binding_keys.add(queue["bindingKey"])
    
    # Verificar se todos os eventos estão cobertos
    missing_events = []
    for event_name, expected_topic in ALBION_EVENTS.items():
        if expected_topic not in binding_keys:
            missing_events.append(f"{event_name} -> {expected_topic}")
    
    if missing_events:
        print("❌ Eventos não cobertos:")
        for event in missing_events:
            print(f"  - {event}")
        return False
    
    print(f"✅ Todos os {len(ALBION_EVENTS)} eventos estão cobertos")
    return True

def print_statistics(config: Dict):
    """Imprime estatísticas da configuração"""
    print("\n📊 ESTATÍSTICAS DA CONFIGURAÇÃO")
    print("=" * 50)
    
    exchanges = config.get("exchanges", [])
    queues = config.get("queues", [])
    
    print(f"📈 Exchanges: {len(exchanges)}")
    print(f"📈 Queues: {len(queues)}")
    print(f"📈 Eventos mapeados: {len(ALBION_EVENTS)}")
    
    # Contar queues por categoria
    categories = {}
    for queue in queues:
        category = queue["name"].split(".")[0]
        categories[category] = categories.get(category, 0) + 1
    
    print("\n📋 Queues por categoria:")
    for category, count in sorted(categories.items()):
        print(f"  - {category}: {count} queues")

def main():
    """Função principal"""
    print("🎯 VALIDADOR DE MAPEAMENTO DE EVENTOS ALBION ONLINE")
    print("=" * 60)
    
    # Carregar configurações
    config_files = ["messaging.settings.json", "messaging.vps.settings.json"]
    
    for config_file in config_files:
        print(f"\n🔧 Validando {config_file}...")
        config = load_config(config_file)
        
        if not config:
            continue
        
        # Executar validações
        exchanges_ok = validate_exchanges(config)
        queues_ok = validate_queues(config)
        coverage_ok = validate_event_coverage(config)
        
        if exchanges_ok and queues_ok and coverage_ok:
            print(f"✅ {config_file} está configurado corretamente!")
            print_statistics(config)
        else:
            print(f"❌ {config_file} tem problemas de configuração")
            return 1
    
    print("\n🎉 Todas as configurações estão válidas!")
    return 0

if __name__ == "__main__":
    sys.exit(main()) 