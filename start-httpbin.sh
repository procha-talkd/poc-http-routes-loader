#!/bin/bash

echo "Starting httpbin service on port 8081..."
docker-compose up -d

echo "Waiting for httpbin to be ready..."
until curl -s http://localhost:8081/status/200 > /dev/null; do
    sleep 1
done

echo "httpbin is ready!"
