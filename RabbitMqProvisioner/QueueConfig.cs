namespace RabbitMqProvisioner;

public record QueueConfig(
    string Name, 
    string BindingKey, 
    string Exchange, 
    bool Durable = true,
    int? MaxLength = null,
    string OverflowBehavior = "drop-head"
)
{
    public Dictionary<string, object> GetArguments()
    {
        var args = new Dictionary<string, object>();
        
        if (MaxLength.HasValue)
        {
            args["x-max-length"] = MaxLength.Value;
            args["x-overflow"] = OverflowBehavior;
        }
        
        return args;
    }
}
