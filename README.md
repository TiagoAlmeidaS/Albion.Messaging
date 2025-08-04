# Albion.Messaging

Infraestrutura de mensageria para o Albion usando RabbitMQ.

## Requisitos

- Docker
- .NET 8 SDK

## Uso

Inicie o RabbitMQ com a UI de gerenciamento:

```bash
docker compose up -d
```

Provisione exchanges e filas declaradas em `configs/messaging.settings.json`:

```bash
dotnet run --project RabbitMqProvisioner
```

Ao terminar, derrube o broker:

```bash
docker compose down
```
