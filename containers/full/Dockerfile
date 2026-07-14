FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    elixir \
    erlang \
    gawk \
    ghc \
    git \
    golang-go \
    jq \
    lua5.4 \
    make \
    nodejs \
    npm \
    ocaml-nox \
    openjdk-21-jdk-headless \
    protobuf-compiler \
    python3 \
    python3-pip \
    racket \
    ruby-full \
    rustc \
    cargo \
    sbcl \
    swi-prolog \
    tcl \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
