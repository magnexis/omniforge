FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    elixir \
    erlang \
    ghc \
    git \
    jq \
    make \
    ocaml-nox \
    python3 \
    python3-pip \
    racket \
    sbcl \
    swi-prolog \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
