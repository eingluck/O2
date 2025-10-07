# Use the official Alpine Linux image as the base
FROM alpine:latest

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package index and install the required packages
# The 'apk update' command updates the repository index.
# The 'apk add' command installs the specified packages and their dependencies.
#   - openssh-client: Provides the ssh command for secure remote login.
#   - sshpass: Used for non-interactive password-based SSH login.
#   - mosquitto-client: Provides the mosquitto_pub and mosquitto_sub commands for MQTT.
# The 'rm -rf /var/cache/apk/*' command cleans up the APK cache to keep the image small.
RUN apk update && \
    apk add openssh-client sshpass mosquitto-client && \
    rm -rf /var/cache/apk/*

# Set the default command for the container
# This is optional, but useful to keep the container running or provide a default utility.
CMD ["/bin/sh"]

# Copiar script principal
WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

