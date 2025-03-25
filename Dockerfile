# Use a Debian-based image as the base.  Debian is a good choice for general-purpose Dart.
FROM debian:bookworm-slim

# Install necessary packages: Dart SDK, curl, and other dependencies.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Download and install the Dart SDK.  Get the latest stable version.
RUN curl -L "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64.zip" > dart.zip && \
    unzip dart.zip -d /usr/local && \
    rm dart.zip

# Set the DART_SDK environment variable.
ENV DART_SDK=/usr/local/dart-sdk
# Add Dart SDK tools to the PATH.
ENV PATH="$PATH:/usr/local/dart-sdk/bin"

# Set the working directory for the Dart application.
WORKDIR /app

# Copy the entire project into the container.
COPY . /app

# Get Dart dependencies.
RUN dart pub get --no-analytics --no-version-check

# Expose the port your application listens on (e.g., 8080).
EXPOSE 8080

# Set the entrypoint to run the Dart application.  Assumes your main file is bin/server.dart.
ENTRYPOINT ["dart", "run", "bin/server.dart"]
