#!/usr/bin/env python3
"""
Script de teste para validar o mapeamento completo de eventos Albion Online para RabbitMQ
"""

import json
import sys
from typing import Dict, List, Set

# Lista completa de eventos mapeados
ALBION_EVENTS = {
    # Clusters e Localização
    "ChangeClusterEvent": "albion.event.changeclusterevent",
    "LoadClusterObjectsEvent": "albion.event.loadclusterobjectsevent", 
    "MistsPlayerJoinedInfoEvent": "albion.event.mistsplayerjoinedinfoevent",
    
    # Jogadores
    "NewCharacterEvent": "albion.event.newcharacterevent",
    "CharacterEquipmentChangedEvent": "albion.event.characterequipmentchangedevent",
    "HealthUpdateEvent": "albion.event.healthupdateevent",
    "RegenerationChangedEvent": "albion.event.regenerationchangedevent",
    "MountedEvent": "albion.event.mountedevent",
    "MoveEvent": "albion.event.moveevent",
    "ChangeFlaggingFinishedEvent": "albion.event.changeflaggingfinishedevent",
    
    # Mobs
    "NewMobEvent": "albion.event.newmobevent",
    "MobChangeStateEvent": "albion.event.mobchangestateevent",
    
    # Recursos
    "NewHarvestableEvent": "albion.event.newharvestableevent",
    "NewHarvestablesListEvent": "albion.event.newharvestableslistevent",
    "HarvestableChangeStateEvent": "albion.event.harvestablechangestateevent",
    
    # Dungeons
    "NewDungeonEvent": "albion.event.newdungeonevent",
    
    # Pesca
    "NewFishingZoneEvent": "albion.event.newfishingzoneevent",
    
    # Wisps
    "NewGatedWispEvent": "albion.event.newgatedwispevent",
    "WispGateOpenedEvent": "albion.event.wispgateopenedevent",
    
    # Baús
    "NewLootChestEvent": "albion.event.newlootchestevent",
    
    # Sincronização
    "KeySyncEvent": "albion.event.keysyncevent",
    
    # Saída
    "LeaveEvent": "albion.event.leaveevent",
    
    # Operações
    "JoinResponseOperation": "albion.event.joinresponseoperation",
    "MoveRequestOperation": "albion.event.moverequestoperation"
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
        "clusters.change": "albion.event.changeclusterevent",
        "clusters.loadobjects": "albion.event.loadclusterobjectsevent",
        "clusters.mistsplayer": "albion.event.mistsplayerjoinedinfoevent",
        "players.newcharacter": "albion.event.newcharacterevent",
        "players.equipment": "albion.event.characterequipmentchangedevent",
        "players.health": "albion.event.healthupdateevent",
        "players.regeneration": "albion.event.regenerationchangedevent",
        "players.mounted": "albion.event.mountedevent",
        "players.move": "albion.event.moveevent",
        "players.flagging": "albion.event.changeflaggingfinishedevent",
        "mobs.new": "albion.event.newmobevent",
        "mobs.state": "albion.event.mobchangestateevent",
        "resources.new": "albion.event.newharvestableevent",
        "resources.list": "albion.event.newharvestableslistevent",
        "resources.state": "albion.event.harvestablechangestateevent",
        "dungeons.new": "albion.event.newdungeonevent",
        "fishing.zone": "albion.event.newfishingzoneevent",
        "fishing.bot.trigger": "fish.*",
        "wisps.new": "albion.event.newgatedwispevent",
        "wisps.gate": "albion.event.wispgateopenedevent",
        "chests.new": "albion.event.newlootchestevent",
        "sync.keys": "albion.event.keysyncevent",
        "objects.leave": "albion.event.leaveevent",
        "operations.join": "albion.event.joinresponseoperation",
        "operations.move": "albion.event.moverequestoperation",
        "sniffer.raw.packets": "albion.packet.*",
        "sniffer.events.newcharacter": "albion.event.newcharacter",
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