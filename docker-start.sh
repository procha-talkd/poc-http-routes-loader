#!/bin/bash

echo "=========================================="
echo "Starting all services with Docker Compose"
echo "=========================================="
echo ""

# Build and start all services
docker-compose up --build -d

echo ""
echo "Waiting for services to be healthy..."
echo ""

# Wait for all services
docker-compose ps

echo ""
echo "=========================================="
echo "Services started successfully!"
echo "=========================================="
echo ""
echo "Available services:"
echo "  - httpbin:       http://localhost:8081"
echo "  - route-server:  http://localhost:9090/routes.yaml"
echo "  - gateway:       http://localhost:8080"
echo ""
echo "Test the gateway:"
echo "  curl http://localhost:8080/get"
echo ""
echo "View logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
