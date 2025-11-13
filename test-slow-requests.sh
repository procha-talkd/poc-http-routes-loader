#!/bin/bash

# Test script specifically for validating in-flight requests survive route reloads
# Uses httpbin's /delay/{n} endpoint to create slow responses that are in-flight during route switches

DELAY="${DELAY:-15}"                    # How long each request takes (seconds)
DURATION="${DURATION:-60}"              # Total test duration (seconds)
RATE="${RATE:-5}"                       # Lower rate since requests are slow (req/s)
SWITCH_INTERVAL="${SWITCH_INTERVAL:-10}" # Switch routes while requests are in-flight

echo "=========================================="
echo "Slow Request (In-Flight) Route Reload Test"
echo "=========================================="
echo ""
echo "This test validates that in-flight requests complete successfully"
echo "even when routes are reloaded while the request is waiting for upstream."
echo ""
echo "Test parameters:"
echo "  - Request delay: ${DELAY}s (each request waits this long)"
echo "  - Route switch interval: ${SWITCH_INTERVAL}s"
echo "  - Test duration: ${DURATION}s"
echo "  - Request rate: ${RATE} req/s"
echo ""
echo "Critical test: Since delay (${DELAY}s) > switch interval (${SWITCH_INTERVAL}s),"
echo "requests will be IN-FLIGHT when routes reload."
echo ""

# Validate that delay > switch_interval to ensure overlap
if [ "$DELAY" -le "$SWITCH_INTERVAL" ]; then
    echo "⚠️  WARNING: DELAY ($DELAY) should be > SWITCH_INTERVAL ($SWITCH_INTERVAL)"
    echo "   for proper in-flight testing. Requests may complete before route switch."
    echo ""
fi

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
TARGET="/delay/${DELAY}"
echo "[$(date +%H:%M:%S)] Starting load test to $TARGET..."

docker exec vegeta-tester sh -c "
  echo 'GET http://gateway:8080$TARGET' | \
  vegeta attack -rate=$RATE -duration=${DURATION}s -timeout=30s | \
  tee /reports/results_slow_${TIMESTAMP}.bin | \
  vegeta encode | \
  while IFS= read -r line; do
    status=\$(echo \"\$line\" | jq -r '.code')
    timestamp=\$(echo \"\$line\" | jq -r '.timestamp')
    latency=\$(echo \"\$line\" | jq -r '.latency')
    
    if [ \"\$status\" != \"200\" ] && [ \"\$status\" != \"null\" ]; then
      echo \"[ERROR] Status \$status at \$(date -Iseconds) (latency: \$latency)\"
    fi
  done
" > reports/live_errors_slow_${TIMESTAMP}.log 2>&1 &

VEGETA_PID=$!

# Give load test time to start
sleep 2

# Start route switching
echo "[$(date +%H:%M:%S)] Starting route switching (every ${SWITCH_INTERVAL}s while requests are in-flight)..."
echo ""

# Initialize with v1
cp routes-v1.yaml routes.yaml
sleep 2

for i in $(seq 1 $ITERATIONS); do
    echo "[$(date +%H:%M:%S)] Switch $i/$ITERATIONS: routes-v1.yaml -> routes-v2.yaml (requests in-flight: ~$((RATE * DELAY)))"
    cp routes-v2.yaml routes.yaml
    
    sleep $SWITCH_INTERVAL
    
    echo "[$(date +%H:%M:%S)] Switch $i/$ITERATIONS: routes-v2.yaml -> routes-v1.yaml (requests in-flight: ~$((RATE * DELAY)))"
    cp routes-v1.yaml routes.yaml
    
    sleep $SWITCH_INTERVAL
done

echo ""
echo "[$(date +%H:%M:%S)] Route switching complete, waiting for load test to finish..."
echo "Note: Final requests may still be waiting for ${DELAY}s delay to complete..."

# Wait for load test to complete
wait $VEGETA_PID

echo ""
echo "[$(date +%H:%M:%S)] Generating reports..."

# Generate reports
docker exec vegeta-tester sh -c "
  vegeta plot /reports/results_slow_${TIMESTAMP}.bin > /reports/plot_slow_${TIMESTAMP}.html
  vegeta report -type=text /reports/results_slow_${TIMESTAMP}.bin > /reports/report_slow_${TIMESTAMP}.txt
  vegeta report -type=json /reports/results_slow_${TIMESTAMP}.bin > /reports/report_slow_${TIMESTAMP}.json
  vegeta report -type=hist[0,5s,10s,15s,20s,25s,30s] /reports/results_slow_${TIMESTAMP}.bin > /reports/histogram_slow_${TIMESTAMP}.txt
"

echo ""
echo "=========================================="
echo "Slow Request Test Complete!"
echo "=========================================="
echo ""

# Show summary
cat reports/report_slow_${TIMESTAMP}.txt

echo ""
echo "Detailed reports in ./reports/:"
echo "  - plot_slow_${TIMESTAMP}.html          (interactive HTML plot)"
echo "  - report_slow_${TIMESTAMP}.txt         (text summary)"
echo "  - histogram_slow_${TIMESTAMP}.txt      (latency distribution)"
echo "  - live_errors_slow_${TIMESTAMP}.log    (real-time error log)"
echo ""

# Check for errors
ERROR_COUNT=$(grep -c "\[ERROR\]" reports/live_errors_slow_${TIMESTAMP}.log 2>/dev/null || echo "0")
ERROR_COUNT=$(echo "$ERROR_COUNT" | tr -d '\n')
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ ZERO ERRORS - In-flight requests completed successfully during route reloads!"
    echo ""
    echo "This proves that Spring Cloud Gateway does NOT cancel in-flight requests"
    echo "when routes are reloaded. Existing connections continue processing."
else
    echo "⚠️  $ERROR_COUNT errors detected - in-flight requests may have been interrupted!"
    echo ""
    echo "This indicates that route reloading may cancel in-flight requests."
    echo "Check live_errors_slow_${TIMESTAMP}.log for details."
fi

echo ""
echo "Open the HTML report:"
echo "  open reports/plot_slow_${TIMESTAMP}.html"
echo ""
echo "Expected latencies: ~${DELAY}s per request"
echo "In-flight requests during each switch: ~$((RATE * DELAY)) concurrent"
echo ""
