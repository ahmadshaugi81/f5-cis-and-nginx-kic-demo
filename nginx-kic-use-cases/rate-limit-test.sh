#!/bin/bash

# Target URL
URL="https://cafe.f5demo.io/tea"
TOTAL_REQUESTS=100
INTERVALS=(0.25 0.5 0.75 1)

# Associative array to store response code counts
declare -A status_counts

echo "Starting $TOTAL_REQUESTS requests to $URL..."

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    # Pick a random interval from the list
    SLEEP_TIME=${INTERVALS[$RANDOM % ${#INTERVALS[@]}]}
    
    # Perform the request and capture the HTTP status code
    # -s: silent, -o /dev/null: discard body, -w: output format
    HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "$URL")
    
    # Increment the count for this specific status code
    ((status_counts[$HTTP_CODE]++))
    
    echo "Request $i: Received $HTTP_CODE (Next wait: ${SLEEP_TIME}s)"
    
    # Wait for the interval before the next request (unless it's the last one)
    if [ $i -lt $TOTAL_REQUESTS ]; then
        sleep $SLEEP_TIME
    fi
done

echo -e "\n--- Final Results ---"
for code in "${!status_counts[@]}"; do
    echo "Response $code: ${status_counts[$code]} times"
done