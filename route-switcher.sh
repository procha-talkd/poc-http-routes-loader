#!/bin/bash

INTERVAL="${INTERVAL:-10}"
ITERATIONS="${ITERATIONS:-5}"

echo "=========================================="
echo "Route Switcher - Zero Downtime Test"
echo "=========================================="
echo "Interval: ${INTERVAL}s"
echo "Iterations: ${ITERATIONS}"
echo ""
echo "This script will alternate between routes-v1.yaml and routes-v2.yaml"
echo "to test zero-downtime route reloading."
echo ""

# Check if route files exist
if [ ! -f "routes-v1.yaml" ] || [ ! -f "routes-v2.yaml" ]; then
    echo "Error: routes-v1.yaml and routes-v2.yaml must exist"
    exit 1
fi

# Start with v1
echo "[$(date +%H:%M:%S)] Initializing with routes-v1.yaml"
cp routes-v1.yaml routes.yaml

sleep 2

for i in $(seq 1 $ITERATIONS); do
    # Switch to v2
    echo "[$(date +%H:%M:%S)] Iteration $i/$ITERATIONS - Switching to routes-v2.yaml (adds /uuid route + v2 headers)"
    cp routes-v2.yaml routes.yaml
    
    sleep $INTERVAL
    
    # Switch to v1
    echo "[$(date +%H:%M:%S)] Iteration $i/$ITERATIONS - Switching to routes-v1.yaml (removes /uuid route + v1 headers)"
    cp routes-v1.yaml routes.yaml
    
    sleep $INTERVAL
done

echo ""
echo "=========================================="
echo "Route switching complete!"
echo "=========================================="
echo "Check the vegeta reports for any errors during route switches"
echo ""
