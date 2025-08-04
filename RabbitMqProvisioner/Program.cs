using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using RabbitMqProvisioner;

var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));

var configuration = new ConfigurationBuilder()
    .SetBasePath(root)
    .AddJsonFile("configs/messaging.settings.json", optional: false, reloadOnChange: false)
    .Build();

var rabbitConfig = configuration.GetSection("rabbitMq").Get<RabbitMqConfig>()
                  ?? throw new InvalidOperationException("rabbitMq settings missing");

var factory = new ConnectionFactory
{
    Uri = new Uri(rabbitConfig.Uri),
    DispatchConsumersAsync = rabbitConfig.DispatchConsumersAsync
};

using var connection = factory.CreateConnection();
using var channel = connection.CreateModel();

var exchanges = configuration.GetSection("exchanges").Get<ExchangeConfig[]>() ?? [];
foreach (var exchange in exchanges)
{
    channel.ExchangeDeclare(exchange.Name, exchange.Type, exchange.Durable, exchange.AutoDelete);
    Console.WriteLine($"✅ Exchange declarada: {exchange.Name}");
}

var queues = configuration.GetSection("queues").Get<QueueConfig[]>() ?? [];
foreach (var queue in queues)
{
    channel.QueueDeclare(queue.Name, queue.Durable, false, false);
    channel.QueueBind(queue.Name, queue.Exchange, queue.BindingKey);
    Console.WriteLine($"✅ Queue ligada: {queue.Name} → {queue.Exchange} ({queue.BindingKey})");
}
