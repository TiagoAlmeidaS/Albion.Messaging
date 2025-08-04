using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using RabbitMqProvisioner;

// No container Docker, o arquivo de configuração está montado em /app/configs/
var configPath = Path.Combine(AppContext.BaseDirectory, "configs", "messaging.settings.json");

var configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile(configPath, optional: false, reloadOnChange: false)
    .Build();

var rabbitConfig = configuration.GetSection("rabbitMq").Get<RabbitMqConfig>()
                  ?? throw new InvalidOperationException("rabbitMq settings missing");

// Detectar se está rodando no Docker e ajustar o hostname
var uri = rabbitConfig.Uri;
if (Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true" || 
    File.Exists("/.dockerenv"))
{
    // Substituir localhost por rabbitmq (nome do serviço no Docker Compose)
    uri = uri.Replace("localhost", "rabbitmq");
    Console.WriteLine("🐳 Executando no Docker - usando hostname 'rabbitmq'");
}
else
{
    Console.WriteLine("💻 Executando localmente - usando hostname 'localhost'");
}

var factory = new ConnectionFactory
{
    Uri = new Uri(uri),
    DispatchConsumersAsync = rabbitConfig.DispatchConsumersAsync
};

// Aguardar o RabbitMQ estar pronto com retry
Console.WriteLine("⏳ Aguardando RabbitMQ estar pronto...");
var maxRetries = 30;
var retryDelay = TimeSpan.FromSeconds(2);

for (int i = 0; i < maxRetries; i++)
{
    try
    {
        using var connection = factory.CreateConnection();
        using var channel = connection.CreateModel();
        
        Console.WriteLine("✅ Conectado ao RabbitMQ com sucesso!");
        
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
        
        Console.WriteLine("🎉 Provisionamento concluído com sucesso!");
        return;
    }
    catch (Exception ex) when (i < maxRetries - 1)
    {
        Console.WriteLine($"⏳ Tentativa {i + 1}/{maxRetries}: RabbitMQ ainda não está pronto... ({ex.Message})");
        Thread.Sleep(retryDelay);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Falha ao conectar ao RabbitMQ após {maxRetries} tentativas: {ex.Message}");
        throw;
    }
}
