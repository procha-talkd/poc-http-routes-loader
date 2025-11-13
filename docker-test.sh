#!/bin/bash

DURATION="${DURATION:-30s}"
RATE="${RATE:-100}"
TARGET="${TARGET:-/get}"

echo "=========================================="
echo "Starting Load Test"
echo "=========================================="
echo ""

# Check if services are running
if ! docker-compose ps | grep -q "gateway.*Up"; then
    echo "Gateway is not running. Please start services first:"
    echo "  ./docker-start.sh"
    exit 1
fi

echo "Running Vegeta load test..."
echo "Duration: $DURATION"
echo "Rate: $RATE req/s"
echo "Target: $TARGET"
echo ""

# Create reports directory if it doesn't exist
mkdir -p reports

# Start vegeta container if not running
docker-compose --profile testing up -d vegeta

# Wait for container to be ready
sleep 2

# Run the load test and generate reports
echo "Generating load test reports..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

docker exec vegeta-tester sh -c "
  echo 'GET http://gateway:8080$TARGET' | \
  vegeta attack -rate=$RATE -duration=$DURATION | \
  tee /reports/results_${TIMESTAMP}.bin | \
  vegeta report -type=text | \
  tee /reports/report_${TIMESTAMP}.txt
  
  vegeta plot /reports/results_${TIMESTAMP}.bin > /reports/plot_${TIMESTAMP}.html
  vegeta report -type=json /reports/results_${TIMESTAMP}.bin > /reports/report_${TIMESTAMP}.json
  vegeta report -type=hist[0,2ms,4ms,6ms,8ms,10ms,20ms,50ms,100ms] /reports/results_${TIMESTAMP}.bin > /reports/histogram_${TIMESTAMP}.txt
"

echo ""
echo "=========================================="
echo "Load Test Complete!"
echo "=========================================="
echo ""
echo "Reports generated in ./reports/:"
echo "  - plot_${TIMESTAMP}.html       (interactive HTML plot)"
echo "  - report_${TIMESTAMP}.txt      (text summary)"
echo "  - report_${TIMESTAMP}.json     (JSON data)"
echo "  - histogram_${TIMESTAMP}.txt   (latency histogram)"
echo "  - results_${TIMESTAMP}.bin     (raw results)"
echo ""
echo "Open the HTML report:"
echo "  open reports/plot_${TIMESTAMP}.html"
echo ""
