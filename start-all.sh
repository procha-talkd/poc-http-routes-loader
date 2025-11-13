#!/bin/bash

# Master script to start all services

set -e

echo "=========================================="
echo "Starting Spring Cloud Gateway Test Setup"
echo "=========================================="
echo ""

# Start httpbin
echo "[1/3] Starting httpbin service..."
./start-httpbin.sh
echo ""

# Start route server
echo "[2/3] Starting route configuration server..."
./start-route-server.sh &
ROUTE_SERVER_PID=$!
sleep 2
echo ""

# Start gateway
echo "[3/3] Starting Spring Cloud Gateway..."
echo "Press Ctrl+C to stop all services"
echo ""

# Trap to cleanup on exit
trap "echo 'Stopping services...'; kill $ROUTE_SERVER_PID 2>/dev/null; docker-compose down; exit" SIGINT SIGTERM

./start-gateway.sh

# Cleanup on normal exit
kill $ROUTE_SERVER_PID 2>/dev/null
docker-compose down
