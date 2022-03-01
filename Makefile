IMAGE_NAME := homelab-home-assistant-wheels
ENABLE_DOCKER_BUILDKIT := y
DOCKER_BUILDKIT_PROGRESS_PLAIN ?= n

include ./.bootstrap/makesystem.mk

ifeq ($(MAKESYSTEM_FOUND),1)
include $(MAKESYSTEM_BASE_DIR)/dockerfile.mk
endif
