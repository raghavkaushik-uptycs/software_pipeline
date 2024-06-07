FROM alpine:latest
RUN mkdir /tmp/app
WORKDIR /tmp/app
COPY . .
CMD ["/bin/sh", "-c", "while true; do sleep 1000; done"]