#!/bin/bash

# Script to run continuous load test with detailed status code reporting

GATEWAY_URL="http://localhost:8080"
TARGET="${TARGET:-/get}"
RATE="${RATE:-100}"  # requests per second

echo "Starting continuous load test..."
echo "Target: $GATEWAY_URL$TARGET"
echo "Rate: $RATE req/s"
echo ""
echo "Press Ctrl+C to stop"
echo "=============================================="

# Run continuous load test and show status codes in real-time
echo "GET $GATEWAY_URL$TARGET" | \
  vegeta attack -rate=$RATE -duration=0 | \
  vegeta encode | \
  vegeta report -type='hist[0,100ms,200ms,300ms,400ms,500ms,1s,2s]' -every=5s
