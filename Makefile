# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /bin/bash

include ./help.mk

.PHONY: start
## Runs the buildbot worker in the background on localhost using a podman
## container. Upon launch, the  logs are followed in the terminal
## (see "follow-logs" target).
## It's safe to ctr-c out of this command once running and following the logs.
# Upstream LLVM port choices:
# lab.llvm.org:9994 = staging
# lab.llvm.org:9990 = production
start: build-image remove-container secret
	@echo "=== Starting container bb-worker..."
	-podman run -d --name bb-worker \
		-e BUILDBOT_WORKER_NAME=standalone-build-x86_64 \
		-e BUILDBOT_INFO_ADMIN=kkleine@redhat.com \
		-e BUILDBOT_MASTER=lab.llvm.org:9994 \
		--secret bb-worker-password \
		bb-worker
	$(MAKE) follow-logs

.PHONY: stop
## Stops the bb-worker container created with "start.
stop:
	@echo "=== Stopping container bb-worker..."
	-podman stop --time 0 bb-worker

.PHONY: build-image
## Builds the bb-worker container image.
build-image:
	@echo "=== Building container image bb-worker..."
	podman build --tag bb-worker -f Dockerfile.bb-worker .

.PHONY: remove-container
## Remove any container with the name bb-worker (if it exists).
remove-container:
	@echo "=== Removing container bb-worker..."
	-podman rm --force --volumes bb-worker

.PHONY: follow-logs
## Shows the output of the bb-worker container (see "start").
## It's safe to ctr-c out of this command, this won't stop any containers.
follow-logs:
	@echo "=== Following logs of bb-worker container..."
	podman logs --follow --names --timestamps bb-worker

PASSWORD_FILE:=./bb-worker/secrets/buildbot-worker-password
.PHONY: secret
## Removes the bb-worker password secret (if exists) and re-creates it. 
secret:
ifeq ($(strip $(shell ls $(PASSWORD_FILE) 2>/dev/null)),)
	@echo "=== ERROR: Please create password file: $(PASSWORD_FILE)"
	exit 1
endif
	@echo "=== Removing secret (if exists): bb-worker-password"
	-podman secret rm bb-worker-password &>/dev/null
	podman secret create bb-worker-password $(PASSWORD_FILE)
	@echo "Creating secret: bb-worker-password"
