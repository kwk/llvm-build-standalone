# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /bin/bash

include ./help.mk

.PHONY: start
## Runs the buildbot worker on localhost using a docker container.
## Upon launch, the compose tool's logs are followed in the terminal.
## It's safe to ctr-c out of this command once running and following the logs.
start:
	docker-compose build
	docker-compose up --remove-orphans -d
	@echo "Following compose logs"
	docker-compose logs -f

.PHONY: stop
## Stops all containers managed by "make start" and removes them immediately.
stop:
	docker-compose stop -t0
	docker-compose rm -f

.PHONY: follow-logs
## Shows the output of running containers managed by "make start"
## It's safe to ctr-c out of this command, this won't stop any containers.
follow-logs:
	docker-compose logs -f
