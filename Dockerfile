FROM alpine:3.18

# PocketBase version
ARG PB_VERSION=0.21.4

RUN apk add --no-cache curl unzip

# download pocketbase
RUN curl -L -o pb.zip https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip \
    && unzip pb.zip \
    && mv pocketbase /usr/local/bin/pocketbase \
    && chmod +x /usr/local/bin/pocketbase \
    && rm pb.zip

# create data folder
RUN mkdir -p /pb_data
WORKDIR /app

EXPOSE 8080

CMD ["pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb_data"]
