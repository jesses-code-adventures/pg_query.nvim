FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    luajit \
    make \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace
