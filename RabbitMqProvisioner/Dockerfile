FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY RabbitMqProvisioner/RabbitMqProvisioner.csproj RabbitMqProvisioner/
COPY RabbitMqProvisioner/*.cs RabbitMqProvisioner/

# Restore dependencies
RUN dotnet restore RabbitMqProvisioner/RabbitMqProvisioner.csproj

# Build the application
RUN dotnet build RabbitMqProvisioner/RabbitMqProvisioner.csproj -c Release -o /app/build

# Publish the application
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS runtime
WORKDIR /app

# Copy the published application
COPY --from=build /app/build .

# Create configs directory
RUN mkdir -p /app/configs

# Set environment variable to indicate running in container
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Set the entry point
ENTRYPOINT ["dotnet", "RabbitMqProvisioner.dll"] 