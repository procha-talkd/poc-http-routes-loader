#!/bin/bash

PORT=9090
ROUTES_FILE="routes.yaml"

if [ ! -f "$ROUTES_FILE" ]; then
    echo "Error: $ROUTES_FILE not found!"
    exit 1
fi

echo "Starting HTTP server on port $PORT to serve $ROUTES_FILE..."
python3 -m http.server $PORT
