FROM ubuntu:18.04
RUN apt-get update && \
    apt-get install -y curl

# Install monitoring agent dependencies
RUN curl -sL https://aka.ms/InstallAzureCLIeb | bash

# Copy monitoring agent scripts or binaries
COPY monitoring-agent /usr/local/bin/monitoring-agent

# Set environment variables
ENV LOG_ANALYTICS_WORKSPACE_IDs=""
ENV LOG_ANALYTICS_SHARED_KEY=""

# Run the monitoring agent
ENTRYPOINT [ "monitoring-agent" ]