FROM alpine:3.18

RUN apk add --no-cache ca-certificates tini
COPY pocketbase /usr/local/bin/pocketbase
RUN chmod +x /usr/local/bin/pocketbase

RUN mkdir -p /pb_data /pb_public
WORKDIR /app

EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb_data", "--publicDir=/pb_public"]
