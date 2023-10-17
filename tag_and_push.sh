#!/bin/bash

# Function to increment version
increment_version() {
  echo "$1" | awk -F. '{$NF = $NF + 1;} 1' OFS=.
}

# Check if .version file exists
if [ -f ./.version ]; then
  # Read the last version from the .version file
  LAST_VERSION=$(cat ./.version)
  # Increment the version number
  VERSION=$(increment_version $LAST_VERSION)
else
  # Prompt for a version number if .version file doesn't exist
  echo "Enter the initial version number (e.g., 1.0.0): "
  read VERSION
fi

# Confirm version
echo "Using version: $VERSION. Is this okay? (y/n)"
read CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Aborted."
  exit 1
fi

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

# Update the .version file with the new version
echo $VERSION > ./.version

echo "Successfully built and pushed hatemjaber/tor-rotator:$VERSION and latest."