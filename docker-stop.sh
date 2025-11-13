#!/bin/bash

echo "Stopping all services..."
docker-compose --profile testing down

echo "Services stopped."
