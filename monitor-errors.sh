#!/bin/bash

# Monitor script that runs load test and detects errors during route changes

GATEWAY_URL="http://localhost:8080"
TARGET="${TARGET:-/get}"
RATE="${RATE:-50}"
LOG_FILE="load-test-errors.log"

echo "Starting error monitoring load test..."
echo "Target: $GATEWAY_URL$TARGET"
echo "Rate: $RATE req/s"
echo "Errors will be logged to: $LOG_FILE"
echo ""
echo "Now modify routes.yaml and watch for errors..."
echo "=============================================="

# Clear previous log
> $LOG_FILE

# Run continuous attack and parse results
echo "GET $GATEWAY_URL$TARGET" | \
  vegeta attack -rate=$RATE -duration=0 | \
  vegeta encode | \
  while IFS= read -r line; do
    # Parse JSON and check for non-200 status codes
    status=$(echo "$line" | jq -r '.code')
    timestamp=$(echo "$line" | jq -r '.timestamp')
    
    if [ "$status" != "200" ] && [ "$status" != "null" ]; then
      echo "[$(date -Iseconds)] ERROR: Status $status at $timestamp" | tee -a $LOG_FILE
      echo "$line" | jq '.' >> $LOG_FILE
    fi
    
    # Show status summary every 100 requests
    count=$((count + 1))
    if [ $((count % 100)) -eq 0 ]; then
      echo "[$(date -Iseconds)] Processed $count requests"
    fi
  done
