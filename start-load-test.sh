#!/bin/bash

# Check if vegeta is installed
if ! command -v vegeta &> /dev/null; then
    echo "Vegeta not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install vegeta
    else
        echo "Please install vegeta manually: https://github.com/tsenart/vegeta"
        exit 1
    fi
fi

GATEWAY_URL="http://localhost:8080"
RATE="${RATE:-50}"  # requests per second
DURATION="${DURATION:-0}"  # 0 means infinite

echo "Starting Vegeta load test..."
echo "Target: $GATEWAY_URL/get"
echo "Rate: $RATE req/s"
echo "Duration: ${DURATION}s (0 = continuous)"
echo ""
echo "Status Code Distribution (updates every 5s):"
echo "=============================================="

# Create vegeta target
echo "GET $GATEWAY_URL/get" | vegeta attack -rate=$RATE -duration=${DURATION}s | vegeta encode | \
while IFS= read -r line; do
    echo "$line"
done | vegeta report -type=text -every=5s
