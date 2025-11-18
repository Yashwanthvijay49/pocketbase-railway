# Dockerfile (robust download + retries + checks)
FROM alpine:3.18

ARG PB_VERSION=latest
ENV TMP_ZIP=/tmp/pb.zip

RUN apk add --no-cache curl unzip bash

# download with retries, check size and unzip
RUN set -eux; \
    try_download() { \
      URL="$1"; \
      echo "Trying URL: $URL"; \
      # retry up to 5 times with exponential backoff
      attempt=1; \
      while [ $attempt -le 5 ]; do \
        echo "curl attempt=$attempt"; \
        # -f fail on HTTP errors, -S show errors, -L follow redirects, -o output
        curl -fSL --retry 3 --retry-delay 2 -o "$TMP_ZIP" "$URL" && break || rc=$?; \
        echo "curl failed (rc=$rc)"; \
        attempt=$((attempt+1)); sleep $((attempt*2)); \
      done; \
      if [ ! -s "$TMP_ZIP" ]; then \
        echo "DOWNLOAD FAILED for $URL - file missing or empty"; return 1; \
      fi; \
      # quick sanity: file size > 1KB
      filesize=$(stat -c%s "$TMP_ZIP" || stat -f%z "$TMP_ZIP"); \
      echo "downloaded size=${filesize} bytes"; \
      if [ "$filesize" -lt 1024 ]; then echo "file too small, likely an HTML error page"; return 2; fi; \
      # ensure it's a zip (unzip will error if not)
      unzip -l "$TMP_ZIP"; \
    }; \
    \
    if [ "$PB_VERSION" = "latest" ]; then \
      URL1="https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip"; \
      URL2="https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip"; \
    else \
      URL1="https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"; \
      URL2="https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip"; \
    fi; \
    # try primary then fallback
    ( try_download "$URL1" ) || ( try_download "$URL2" ) || ( echo "All download attempts failed."; exit 1 ); \
    unzip "$TMP_ZIP" -d /tmp; \
    mv /tmp/pocketbase /usr/local/bin/pocketbase; chmod +x /usr/local/bin/pocketbase; rm -f "$TMP_ZIP"

# create data folder
RUN mkdir -p /pb_data
WORKDIR /app

EXPOSE 8080

CMD ["pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb_data"]
