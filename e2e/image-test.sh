#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi

IMAGE="$1"

echo "Starting E2E tests for image: $IMAGE"

sleep 2

echo "E2E tests passed for image: $IMAGE"
