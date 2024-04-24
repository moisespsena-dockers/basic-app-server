DOCKER_CMD ?= docker
DOCKER_USERNAME ?= moisespsena
APPLICATION_NAME ?= basic-app-server
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

docker_deps: build_httpdx

docker_build:
	$(DOCKER_CMD) build --build-arg HTTPDX_PORT=$(HTTPDX_PORT) --tag ${tag}:${GIT_HASH} .

docker_run:
	$(DOCKER_CMD) run -v basic-app-server_data:/data -e POSTGRES_PASSWORD=password -p ${ADDR}:${HTTPDX_PORT} ${tag}:${GIT_HASH}

docker_shell:
	$(DOCKER_CMD) run -it -v basic-app-server_data:/data -p ${ADDR}:${HTTPDX_PORT} ${tag}:${GIT_HASH} bash

docker_push: docker_build
	$(DOCKER_CMD) push ${tag}:${GIT_HASH}
	$(DOCKER_CMD) tag  ${tag}:${GIT_HASH} ${tag}:latest

docker_release: docker_push
	$(DOCKER_CMD) pull ${tag}:${GIT_HASH}
	$(DOCKER_CMD) push ${tag}:latest
