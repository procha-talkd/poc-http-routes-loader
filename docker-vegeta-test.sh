#!/bin/bash

GATEWAY_URL="${GATEWAY_URL:-http://gateway:8080}"
TARGET="${TARGET:-/get}"
RATE="${RATE:-100}"

echo "=========================================="
echo "Vegeta Load Test - Error Monitoring"
echo "=========================================="
echo "Target: $GATEWAY_URL$TARGET"
echo "Rate: $RATE req/s"
echo ""
echo "Waiting for gateway to be ready..."

# Wait for gateway
until curl -s "$GATEWAY_URL/get" > /dev/null 2>&1; do
    echo "Gateway not ready, waiting..."
    sleep 2
done

echo "Gateway is ready! Starting load test..."
echo "Monitoring for errors (non-200 status codes)..."
echo "=========================================="
echo ""

error_count=0
total_count=0

# Run continuous attack and parse results
echo "GET $GATEWAY_URL$TARGET" | \
  vegeta attack -rate=$RATE -duration=0 | \
  vegeta encode | \
  while IFS= read -r line; do
    status=$(echo "$line" | jq -r '.code')
    timestamp=$(echo "$line" | jq -r '.timestamp')
    latency=$(echo "$line" | jq -r '.latency')
    
    total_count=$((total_count + 1))
    
    if [ "$status" != "200" ] && [ "$status" != "null" ]; then
      error_count=$((error_count + 1))
      echo "[ERROR] Status $status at $(date -Iseconds) | Latency: $latency"
    fi
    
    # Show summary every 100 requests
    if [ $((total_count % 100)) -eq 0 ]; then
      error_rate=$(echo "scale=2; $error_count * 100 / $total_count" | bc 2>/dev/null || echo "0")
      echo "[SUMMARY] Requests: $total_count | Errors: $error_count | Error Rate: ${error_rate}%"
    fi
  done
