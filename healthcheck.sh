#!/bin/bash

# Set ARIA2RPCPORT to 6800 if it's not set
ARIANGPORT="${ARIANGPORT:-6888}"

# Define the URL with the specified port
HEALTHCHECK_URL="http://localhost:$ARIANGPORT"

# Use curl to send an HTTP GET request to the specified URL
if curl --output /dev/null --silent --head --fail "$HEALTHCHECK_URL"; then
  echo "Service is healthy."
  exit 0
else
  echo "Service is not healthy."
  exit 1
fi
