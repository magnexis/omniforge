FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    gfortran \
    git \
    jq \
    make \
    octave \
    python3 \
    python3-pip \
    r-base \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
