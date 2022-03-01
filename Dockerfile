# syntax=docker/dockerfile:1.3

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS builder

SHELL ["/bin/bash", "-c"]

ARG HOME_ASSISTANT_VERSION
ARG PIP_VERSION
ARG WHEEL_VERSION
ARG PACKAGES_TO_INSTALL

COPY patches /patches

RUN \
    set -e -o pipefail \
    # Install build dependencies. \
    && homelab install util-linux \
    # autoconf build-essential rustc cargo python3-dev \
    # Install dependencies. \
    && homelab install ${PACKAGES_TO_INSTALL:?} \
    && mkdir -p /root/ha /root/ha/homeassistant /wheels

WORKDIR /root/ha

# hadolint ignore=DL4006,SC1091
RUN \
    set -e -o pipefail \
    # Download the home assistant core and the full module dependency list. \
    && curl --silent --location --remote-name https://raw.githubusercontent.com/home-assistant/core/${HOME_ASSISTANT_VERSION:?}/requirements_all.txt \
    && curl --silent --location --remote-name https://raw.githubusercontent.com/home-assistant/core/${HOME_ASSISTANT_VERSION:?}/requirements.txt \
    && curl --silent --location --remote-name --output-dir ./homeassistant https://raw.githubusercontent.com/home-assistant/core/${HOME_ASSISTANT_VERSION:?}/homeassistant/package_constraints.txt \
    # Patch the requirements.txt to disable modules which require \
    # conflicting dependency versions. \
    && (find /patches -iname *.diff -print0 | sort -z | xargs -0 -n 1 patch -p1 -i) \
    # Set up the virtual environment for building the wheels. \
    && python3 -m venv . \
    && source bin/activate \
    && pip3 install --no-cache-dir --upgrade pip==${PIP_VERSION:?} \
    && pip3 install --no-cache-dir --upgrade wheel==${WHEEL_VERSION:?} \
    # Build the wheels. \
    && MAKEFLAGS="-j$(nproc)" pip3 wheel \
        --no-cache-dir \
        --no-clean \
        --progress-bar off \
        --wheel-dir=/wheels \
        --requirement requirements.txt \
        --requirement requirements_all.txt

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

RUN --mount=type=bind,target=/builder,from=builder,source=/wheels \
    set -e -o pipefail \
    && mkdir -p /ha-wheels \
    && cp -rf /builder/* /ha-wheels/

ENV USER=${USER_NAME}
ENV PATH="/opt/bin:${PATH}"
