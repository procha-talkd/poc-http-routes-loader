#!/bin/bash

DURATION="${DURATION:-120}"
RATE="${RATE:-100}"
TARGET="${TARGET:-/get}"
SWITCH_INTERVAL="${SWITCH_INTERVAL:-10}"

echo "=========================================="
echo "Zero-Downtime Route Reload Test"
echo "=========================================="
echo ""
echo "This test will:"
echo "  1. Start a load test at $RATE req/s for ${DURATION}s"
echo "  2. Switch routes every ${SWITCH_INTERVAL}s during the load test"
echo "  3. Monitor for any errors or downtime"
echo ""

# Check if services are running
if ! docker-compose ps | grep -q "gateway.*Up"; then
    echo "Gateway is not running. Please start services first:"
    echo "  ./docker-start.sh"
    exit 1
fi

# Check if route files exist
if [ ! -f "routes-v1.yaml" ] || [ ! -f "routes-v2.yaml" ]; then
    echo "Error: routes-v1.yaml and routes-v2.yaml must exist"
    exit 1
fi

# Create reports directory
mkdir -p reports

# Start vegeta container if not running
docker-compose --profile testing up -d vegeta
sleep 2

# Calculate iterations based on duration and interval
ITERATIONS=$((DURATION / (SWITCH_INTERVAL * 2)))
echo "Will perform $ITERATIONS route switch cycles"
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Start load test in background
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "[$(date +%H:%M:%S)] Starting load test..."

docker exec vegeta-tester sh -c "
  echo 'GET http://gateway:8080$TARGET' | \
  vegeta attack -rate=$RATE -duration=${DURATION}s | \
  tee /reports/results_${TIMESTAMP}.bin | \
  vegeta encode | \
  while IFS= read -r line; do
    status=\$(echo \"\$line\" | jq -r '.code')
    timestamp=\$(echo \"\$line\" | jq -r '.timestamp')
    
    if [ \"\$status\" != \"200\" ] && [ \"\$status\" != \"null\" ]; then
      echo \"[ERROR] Status \$status at \$(date -Iseconds)\"
    fi
  done
" > reports/live_errors_${TIMESTAMP}.log 2>&1 &

VEGETA_PID=$!

# Give load test time to start
sleep 2

# Start route switching
echo "[$(date +%H:%M:%S)] Starting route switching (every ${SWITCH_INTERVAL}s)..."
echo ""

# Initialize with v1
cp routes-v1.yaml routes.yaml
sleep 2

for i in $(seq 1 $ITERATIONS); do
    echo "[$(date +%H:%M:%S)] Switch $i/$ITERATIONS: routes-v1.yaml -> routes-v2.yaml"
    cp routes-v2.yaml routes.yaml
    
    sleep $SWITCH_INTERVAL
    
    echo "[$(date +%H:%M:%S)] Switch $i/$ITERATIONS: routes-v2.yaml -> routes-v1.yaml"
    cp routes-v1.yaml routes.yaml
    
    sleep $SWITCH_INTERVAL
done

echo ""
echo "[$(date +%H:%M:%S)] Route switching complete, waiting for load test to finish..."

# Wait for load test to complete
wait $VEGETA_PID

echo ""
echo "[$(date +%H:%M:%S)] Generating reports..."

# Generate reports
docker exec vegeta-tester sh -c "
  vegeta plot /reports/results_${TIMESTAMP}.bin > /reports/plot_${TIMESTAMP}.html
  vegeta report -type=text /reports/results_${TIMESTAMP}.bin > /reports/report_${TIMESTAMP}.txt
  vegeta report -type=json /reports/results_${TIMESTAMP}.bin > /reports/report_${TIMESTAMP}.json
  vegeta report -type=hist[0,2ms,4ms,6ms,8ms,10ms,20ms,50ms,100ms] /reports/results_${TIMESTAMP}.bin > /reports/histogram_${TIMESTAMP}.txt
"

echo ""
echo "=========================================="
echo "Zero-Downtime Test Complete!"
echo "=========================================="
echo ""

# Show summary
cat reports/report_${TIMESTAMP}.txt

echo ""
echo "Detailed reports in ./reports/:"
echo "  - plot_${TIMESTAMP}.html          (interactive HTML plot)"
echo "  - report_${TIMESTAMP}.txt         (text summary)"
echo "  - histogram_${TIMESTAMP}.txt      (latency distribution)"
echo "  - live_errors_${TIMESTAMP}.log    (real-time error log)"
echo ""

# Check for errors
ERROR_COUNT=$(grep -c "\[ERROR\]" reports/live_errors_${TIMESTAMP}.log 2>/dev/null || echo "0")
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ ZERO ERRORS - Route reloading had no downtime!"
else
    echo "⚠️  $ERROR_COUNT errors detected - check live_errors_${TIMESTAMP}.log"
fi

echo ""
echo "Open the HTML report:"
echo "  open reports/plot_${TIMESTAMP}.html"
echo ""
