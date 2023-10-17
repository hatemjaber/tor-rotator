# Tor Rotator

## Description

The Tor Rotator is a Dockerized solution that provides scalable and secure access to the Tor network. Not only does it allow you to rotate your Tor identity through a Python script, but it also lets you scale the number of Tor instances running behind a HAProxy load balancer. This makes it ideal for developers, researchers, and enthusiasts who need anonymity and robustness for their applications.

## Key Features

- **Automated Identity Rotation**: A Python script and cron job allow for automatic rotation of Tor identity.

- **Security**: Automatically generates a hashed control password to secure your Tor instances.

- **Customizable Instance Count**: Choose the number of Tor instances you want to run via an environment variable.

- **Load Balanced**: Sits behind a HAProxy load balancer to distribute the load across multiple Tor instances. (default 5)

- **Open Source**: Extend and customize to suit your specific needs.

## Usage

1. Build or pull the Docker image.
2. Run the container, specifying any environment variables if needed (e.g., the number of Tor instances).
3. Use the Python script inside the container to programmatically rotate Tor identities.

> **Note**: You must have Docker installed to use this service. For detailed instructions and further configuration options, consult the project documentation.

## Docker-Compose Sample

Here's an example `docker-compose.yml` file for deploying the service:

```yaml
version: '3.9'
services:
  tor-service:
    container_name: tor-service
    image: hatemjaber/tor-rotator:latest
    ports:
      - "9000:9000" # Control Port for HAProxy
    environment:
      - NUM_TOR_INSTANCES=7
```

This configuration lets you specify the number of Tor instances you want to run, which will be load balanced by HAProxy.
