using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using RabbitMqProvisioner;

// Detectar o caminho correto do arquivo de configuração
string configPath;
if (Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true" || 
    File.Exists("/.dockerenv"))
{
    // No container Docker, o arquivo está montado em /app/configs/
    configPath = Path.Combine(AppContext.BaseDirectory, "configs", "messaging.settings.json");
}
else
{
    // Localmente, procurar no diretório raiz do projeto
    var projectRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));
    configPath = Path.Combine(projectRoot, "configs", "messaging.settings.json");
}

var configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile(configPath, optional: false, reloadOnChange: false)
    .Build();

var rabbitConfig = configuration.GetSection("rabbitMq").Get<RabbitMqConfig>()
                  ?? throw new InvalidOperationException("rabbitMq settings missing");

// Detectar ambiente e ajustar hostname automaticamente
var uri = rabbitConfig.Uri;
if (Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true" || 
    File.Exists("/.dockerenv"))
{
    // Substituir qualquer hostname por rabbitmq (nome do serviço no Docker Compose)
    var uriBuilder = new UriBuilder(uri);
    uriBuilder.Host = "rabbitmq";
    uri = uriBuilder.ToString();
    Console.WriteLine("🐳 Executando no Docker - usando hostname 'rabbitmq'");
}
else if (uri.Contains("tastechdeveloper.shop"))
{
    Console.WriteLine("🌐 Conectando na VPS: tastechdeveloper.shop");
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
            var arguments = queue.GetArguments();
            channel.QueueDeclare(queue.Name, queue.Durable, false, false, arguments);
            channel.QueueBind(queue.Name, queue.Exchange, queue.BindingKey);
            
            var limitInfo = queue.MaxLength.HasValue 
                ? $" [Max: {queue.MaxLength}, Overflow: {queue.OverflowBehavior}]" 
                : "";
            Console.WriteLine($"✅ Queue ligada: {queue.Name} → {queue.Exchange} ({queue.BindingKey}){limitInfo}");
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
