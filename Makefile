# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /bin/bash

include ./help.mk

.PHONY: all
## Runs these targets to help you get started:
## build-image, remove-container, secret start, follow-logs
all: build-image remove-container secret start follow-logs

.PHONY: start
## Runs the buildbot worker in the background on localhost using a podman
## container.
start:
	@echo "=== Starting container bb-worker..."
	podman run -d --name bb-worker \
		-e BUILDBOT_WORKER_NAME=standalone-build-x86_64 \
		-e BUILDBOT_INFO_ADMIN=kkleine@redhat.com \
		-e BUILDBOT_MASTER=lab.llvm.org:9994 \
		--secret bb-worker-password \
		bb-worker

.PHONY: stop
## Stops the bb-worker container created with "start".
stop:
	@echo "=== Stopping container bb-worker..."
	-podman stop --time 0 bb-worker

.PHONY: build-image
## Builds the bb-worker container image.
build-image: Dockerfile.bb-worker
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
SECRET_NAME:=bb-worker-password
.PHONY: secret
## Checks if the podman secret called 'bb-worker-password' exists. If it doesn't
## then it calls 'make update-secret'
secret:
	@echo "=== Checking if podman secret exists: $(SECRET_NAME)"
ifeq ($(strip $(shell podman secret inspect --format '{{.Spec.Name}}' $(SECRET_NAME) 2>/dev/null)),)
	$(MAKE) update-secret 
else
	@echo 'Podman secret already exists: $(SECRET_NAME)'
endif

.PHONY: update-secret
## Checks for a password in ./bb-worker/secrets/bb-worker-password and updates
## or creates the podman secret 'bb-worker-password' from it.
update-secret:
	@echo "=== Updating podman secret: $(SECRET_NAME)"
ifeq ($(strip $(shell ls $(PASSWORD_FILE) 2>/dev/null)),)
	@echo "=== ERROR: Please create password file: $(PASSWORD_FILE)"
	exit 1
endif
	@echo "=== Removing podman secret (if exists): $(SECRET_NAME)"
	-podman secret rm $(SECRET_NAME) &>/dev/null
	@echo "=== Creating podman secret: $(SECRET_NAME)"
	podman secret create $(SECRET_NAME) $(PASSWORD_FILE)
	@echo 
	@echo "WARNING: We highly recommend that you delete the password file: $(PASSWORD_FILE)"
	@echo
	
