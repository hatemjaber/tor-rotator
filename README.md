# Tor Rotator

## Description

The Tor Rotator is a Dockerized solution that provides easy and secure access to the Tor network, allowing you to rotate your Tor identity with a simple Python script. This service is designed for developers, researchers, and enthusiasts who need anonymity and the ability to work with Tor programmatically.

## Key Features

- **Automated Identity Rotation**: The service includes a Python script that automates the process of rotating your Tor identity. This is useful for various applications where anonymity is required.
  
- **Security**: It generates a hashed control password to secure your Tor instance, ensuring your anonymity and privacy while using Tor.
  
- **Environment Variables for Authorization**: You can customize the username and password for the HAProxy instance via environment variables, allowing for easier and more secure deployments.

- **Customizable**: The Docker image is built with flexibility in mind, making it easy to configure and integrate into your projects.
  
- **Open Source**: This service is open-source, allowing you to customize and extend it to meet your specific needs.

## Usage

1. Pull the Docker image.
2. Start the container.
3. Utilize the provided Python script to rotate your Tor identity.

## Sample Docker-Compose File

```yaml
version: '3.9'

services:
  tor-service:
    container_name: tor-service
    build: .
    ports:
      - "0.0.0.0:9000:9000" # HAProxy Port
      # - "0.0.0.0:9001:9001"
    environment:
      - NUM_TOR_INSTANCES=2 # Number of Tor instances you want to run; default is 5
      - HAPROXY_USERNAME=admin # Default value is admin
      - HAPROXY_PASSWORD=admin # Default value is admin
