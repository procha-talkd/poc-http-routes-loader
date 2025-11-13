# Spring Cloud Gateway with Hot-Reload Routes

A Spring Cloud Gateway implementation that dynamically loads and refreshes routing configuration from an external HTTP endpoint without requiring restarts.

## Features

- **Hot-Reload Routes**: Automatically fetches route definitions from an HTTP endpoint every 5 seconds
- **Zero Downtime**: Route changes are applied without restarting the gateway
- **YAML Configuration**: Routes defined in simple YAML format
- **No Actuator Required**: Custom implementation using Spring's `RouteDefinitionLocator` and event system

## Architecture

- **HttpRouteDefinitionLocator**: Custom `RouteDefinitionLocator` that fetches routes from HTTP endpoint
- **RouteRefreshScheduler**: Scheduled task that polls for changes and publishes `RefreshRoutesEvent`
- **Route Server**: Simple HTTP server serving `routes.yaml` file

## Quick Start

### Prerequisites

- Java 17+
- Python 3
- Gradle (wrapper included)

### Running

1. **Start the route configuration server** (Terminal 1):
   ```bash
   ./start-route-server.sh
   ```
   This serves `routes.yaml` on port 9090.

2. **Start the gateway** (Terminal 2):
   ```bash
   ./start-gateway.sh
   ```
   Gateway runs on port 8080.

3. **Test a route**:
   ```bash
   curl http://localhost:8080/hello
   ```

### Modifying Routes

Edit `routes.yaml` and save. The gateway will pick up changes within 5 seconds.

Example route definition:
```yaml
- id: my-route
  uri: https://example.com
  predicates:
    - Path=/my-path/**
  filters:
    - StripPrefix=1
```

## Configuration

Edit `src/main/resources/application.yml`:

- `gateway.routes.url`: HTTP endpoint serving routes (default: `http://localhost:9090/routes.yaml`)
- `gateway.routes.refresh-interval`: Polling interval in milliseconds (default: `5000`)

## Tech Stack

- Spring Boot 3.2.0
- Spring Cloud Gateway 2023.0.0
- Kotlin 1.9.20
- Gradle (Kotlin DSL)
