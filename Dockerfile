# Dockerfile - PocketBase (robust download)
FROM alpine:3.18

# Use latest PocketBase by default (you can override with --build-arg PB_VERSION=...)
ARG PB_VERSION=latest

RUN apk add --no-cache curl unzip

# Download the official Linux binary from GitHub releases (uses 'latest' redirect when PB_VERSION=latest).
# -f : fail on HTTP errors (so build fails immediately if URL returns 404/403)
# -S : show error if curl fails
# -L : follow redirects
# We try two possible filenames: the "generic" latest asset, and fallback to versioned filename if needed.
RUN set -eux; \
    if [ "$PB_VERSION" = "latest" ]; then \
      URL="https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip"; \
    else \
      URL="https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"; \
    fi; \
    echo "Downloading PocketBase from: $URL"; \
    curl -fSL -o /tmp/pb.zip "$URL"; \
    unzip /tmp/pb.zip -d /tmp; \
    mv /tmp/pocketbase /usr/local/bin/pocketbase; \
    chmod +x /usr/local/bin/pocketbase; \
    rm -f /tmp/pb.zip

# create data folder
RUN mkdir -p /pb_data
WORKDIR /app

EXPOSE 8080

CMD ["pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb_data"]
