# syntax=docker/dockerfile:1.3

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
ARG CRYPTOGRAPHY_WHEELS_IMAGE_NAME
ARG CRYPTOGRAPHY_WHEELS_IMAGE_TAG
FROM ${CRYPTOGRAPHY_WHEELS_IMAGE_NAME}:${CRYPTOGRAPHY_WHEELS_IMAGE_TAG} AS builder

SHELL ["/bin/bash", "-c"]

ARG HASS_PKG_UTIL_VERSION
ARG HOME_ASSISTANT_VERSION
ARG PIP_VERSION
ARG WHEEL_VERSION
ARG PACKAGES_TO_INSTALL

RUN \
    set -e -o pipefail \
    # Install build dependencies. \
    && homelab install util-linux mount \
    # autoconf build-essential rustc cargo python3-dev \
    # Install dependencies. \
    && homelab install ${PACKAGES_TO_INSTALL:?} \
    && mkdir -p /config /root/hass /wheels

COPY config/disabled-integrations.txt /config/
COPY config/enabled-integrations.txt /config/

WORKDIR /root/hass

# hadolint ignore=DL4006,SC1091
RUN \
    set -e -o pipefail \
    # Install hasspkgutil. \
    && homelab install-tuxdude-go-package TuxdudeHomeLab/hasspkgutil ${HASS_PKG_UTIL_VERSION:?} \
    # Generate the requirements and constraint list for Home Assistant \
    # Core and also all the integrations we want to enable. \
    && hasspkgutil \
        -ha-version ${HOME_ASSISTANT_VERSION:?} \
        -enabled-integrations /config/enabled-integrations.txt \
        -disabled-integrations /config/disabled-integrations.txt \
        -output-requirements requirements.txt \
        -output-constraints constraints.txt \
    && cp requirements.txt /wheels/build_requirements.txt \
    && cp constraints.txt /wheels/build_constraints.txt \
    # Set up the virtual environment for building the wheels. \
    && python3 -m venv . \
    && source bin/activate \
    && pip3 install --no-cache-dir --progress-bar off --upgrade pip==${PIP_VERSION:?} \
    && pip3 install --no-cache-dir --progress-bar off --upgrade wheel==${WHEEL_VERSION:?} \
    # Build the wheels. \
    && MAKEFLAGS="-j$(nproc)" pip3 wheel \
        --no-cache-dir \
        --progress-bar off \
        --wheel-dir=/wheels \
        --find-links=/wheels \
        --requirement requirements.txt \
        --constraint constraints.txt

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

RUN --mount=type=bind,target=/builder,from=builder,source=/wheels \
    set -e -o pipefail \
    && mkdir -p /wheels \
    && cp -rf /builder/* /wheels/

ENV USER=${USER_NAME}
ENV PATH="/opt/bin:${PATH}"
