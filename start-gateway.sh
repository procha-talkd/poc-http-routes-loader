#!/bin/bash

echo "Building Spring Cloud Gateway..."
./gradlew build -x test

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Starting Spring Cloud Gateway on port 8080..."
./gradlew bootRun
