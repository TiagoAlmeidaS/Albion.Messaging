namespace RabbitMqProvisioner;

public record ExchangeConfig(string Name, string Type = "topic", bool Durable = true, bool AutoDelete = false);
