FROM ubuntu:24.04

RUN apt-get update -q && \
    apt-get install -y -q --no-install-recommends cloud-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cloud-init", "schema", "--config-file"]
