# Tor Rotator

## Description

The Tor Rotator is a Dockerized solution that provides easy and secure access to
the Tor network, allowing you to rotate your Tor identity with a simple Python
script. This service is designed for developers, researchers, and enthusiasts
who need anonymity and the ability to work with Tor programmatically.

## Key Features

- **Automated Identity Rotation**: The service includes a Python script that
  automates the process of rotating your Tor identity. This is useful for
  various applications where anonymity is required.

- **Security**: It generates a hashed control password to secure your Tor
  instance, ensuring your anonymity and privacy while using Tor.

- **Environment Variables for Authorization**: You can customize the username
  and password for the HAProxy instance via environment variables, allowing for
  easier and more secure deployments.

- **Customizable Timeouts**: Configure HAProxy timeouts to match your needs,
  especially useful for slower Tor connections.

- **Customizable**: The Docker image is built with flexibility in mind, making
  it easy to configure and integrate into your projects.

- **Open Source**: This service is open-source, allowing you to customize and
  extend it to meet your specific needs.

## Usage

1. Pull the Docker image.
2. Start the container.
3. Utilize the provided Python script to rotate your Tor identity.

## Environment Variables

The following environment variables can be configured:

| Variable                    | Description                          | Default |
| --------------------------- | ------------------------------------ | ------- |
| `NUM_TOR_INSTANCES`         | Number of Tor instances to run       | 5       |
| `HAPROXY_USERNAME`          | Username for HAProxy authentication  | admin   |
| `HAPROXY_PASSWORD`          | Password for HAProxy authentication  | admin   |
| `HAPROXY_TIMEOUT_CONNECT`   | Time to establish a connection       | 5s      |
| `HAPROXY_TIMEOUT_CLIENT`    | Time for client inactivity           | 20s     |
| `HAPROXY_TIMEOUT_SERVER`    | Time for server inactivity           | 20s     |
| `HAPROXY_RETRIES`           | Number of connection retries         | 3       |
| `ROTATION_INTERVAL_MINUTES` | Identity rotation interval (minutes) | 5       |

Note: For Tor connections, you might want to increase the timeout values as Tor
connections can be slower than regular connections.

## Sample Docker-Compose File

```yaml
version: "3.9"

services:
  tor-service:
    image: hatemjaber/tor-rotator
    container_name: tor-service
    ports:
      - "0.0.0.0:9000:9000" # HAProxy Port with user auth admin:admin@127.0.0.1:9000
    # - "0.0.0.0:9001:9001"
    # - "0.0.0.0:9002:9002" # HAProxy Port without user auth 127.0.0.1:9002
    environment:
      - NUM_TOR_INSTANCES=2 # Number of Tor instances you want to run; default is 5
      - HAPROXY_USERNAME=admin # Default value is admin
      - HAPROXY_PASSWORD=admin # Default value is admin
      - HAPROXY_TIMEOUT_CONNECT=30s # Increased timeout for Tor connections
      - HAPROXY_TIMEOUT_CLIENT=60s # Increased client timeout
      - HAPROXY_TIMEOUT_SERVER=60s # Increased server timeout
      - HAPROXY_RETRIES=3 # Number of retries
      - ROTATION_INTERVAL_MINUTES=10 # Rotate identity every 10 minutes
```

## Sample Usage (change USERNAME:PASSWORD@YOUR-IP-ADDRESS:9000)

```shell
curl -v --proxy admin:admin@127.0.0.1:9000 http://httpbin.io/ip
```
