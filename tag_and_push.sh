#!/bin/bash

# Check if version argument was passed
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Set the version number
VERSION=$1

# Build the Docker image
docker build -t hatemjaber/tor-rotator:$VERSION .
if [ $? -ne 0 ]; then
  echo "Docker build failed."
  exit 1
fi

# Tag the image as latest
docker tag hatemjaber/tor-rotator:$VERSION hatemjaber/tor-rotator:latest

# Push to Docker Hub
docker push hatemjaber/tor-rotator:$VERSION
if [ $? -ne 0 ]; then
  echo "Docker push failed for version $VERSION."
  exit 1
fi

docker push hatemjaber/tor-rotator:latest
if [ $? -ne 0 ]; then
  echo "Docker push failed for latest."
  exit 1
fi

echo "Successfully built and pushed hatemjaber/tor-rotator:$VERSION and latest."
