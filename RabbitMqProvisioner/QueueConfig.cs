namespace RabbitMqProvisioner;

public record QueueConfig(string Name, string BindingKey, string Exchange, bool Durable = true);
