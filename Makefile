DOCKER_CMD ?= docker
DOCKER_USERNAME ?= moisespsena
APPLICATION_NAME ?= minimal-server
ADDR ?= ":10000"
HTTPDX_PORT ?= 80
GIT_HASH ?= $(shell git log --date=format:'%Y%m%d%H%M%S' --format="%h-%cd" -n 1)
tag := ${DOCKER_USERNAME}/${APPLICATION_NAME}

build_httpdx:
	$(DOCKER_CMD) run \
		--user $(shell id -u):$(shell id -g) \
		-v $(shell pwd)/bin:/build \
		-i \
		-e GOCACHE=/build/.gocache_docker \
		golang:1.22-bullseye \
		bash -c 'go install -ldflags="-X main.buildTime=$$(date +%s)" github.com/moisespsena-go/httpdx@latest && rm -rf /build/.gocache_docker && mv /go/bin/httpdx /build/httpdx'

deps: build_httpdx

build:
	$(DOCKER_CMD) build --build-arg HTTPDX_PORT=$(HTTPDX_PORT) --tag ${tag}:${GIT_HASH} .
	$(DOCKER_CMD) tag  ${tag}:${GIT_HASH} ${tag}:latest

run:
	$(DOCKER_CMD) run -v minimal-server_data:/data -e POSTGRES_PASSWORD=password -p ${ADDR}:${HTTPDX_PORT} ${tag}:${GIT_HASH}

shell:
	$(DOCKER_CMD) run -it -v minimal-server_data:/data -p ${ADDR}:${HTTPDX_PORT} ${tag}:${GIT_HASH} bash

push: build
	$(DOCKER_CMD) push ${tag}:${GIT_HASH}
	$(DOCKER_CMD) tag  ${tag}:${GIT_HASH} ${tag}:latest

release: push
	$(DOCKER_CMD) pull ${tag}:${GIT_HASH}
	$(DOCKER_CMD) push ${tag}:latest
