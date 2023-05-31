# APP=$(shell basename $(shell git remote get-url origin))  #  $(APP)    shell dpkg --print-architecture
APP=$(subst .git,,$(shell basename $(shell git remote get-url origin)))
# REGISTRY=ghcr.io/evgenpavlyuchek
REGISTRY=terr
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=linux #linux darwin windows
TARGETARCH=arm64 #amd64 arm64 arm i386

# linux: $(eval TARGETOS=linux) $(eval TARGETARCH=arm) build
# arm: $(eval TARGETOS=arm) $(eval TARGETARCH=arm64) build
# macos: $(eval TARGETOS=darwin) $(eval TARGETARCH=arm) build
# windows: $(eval TARGETOS=windows) $(eval TARGETARCH=arm64) build

ifneq ($(findstring $(MAKECMDGOALS), "linux32"),)
	TARGETOS = linux
	TARGETARCH = arm
endif

ifneq ($(findstring $(MAKECMDGOALS), "linux64"),)
	TARGETOS = linux
	TARGETARCH = arm64
endif

ifneq ($(findstring $(MAKECMDGOALS), "linux"),)
	TARGETOS = linux
	TARGETARCH = arm
endif

ifneq ($(findstring $(MAKECMDGOALS), "arm"),)
	TARGETOS = windows
	TARGETARCH = arm64
endif

ifneq ($(findstring $(MAKECMDGOALS), "macos"),)
	TARGETOS = darwin
	TARGETARCH = arm64
endif

ifneq ($(findstring $(MAKECMDGOALS), "windows"),)
	TARGETOS = windows
	TARGETARCH = arm64
endif

linux32 , linux64 , linux , arm , macos , windows: build


format:
	gofmt -s -w ./

lint:
	golint

test:
	go test -v

get:
	go get

build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o tbot -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=${VERSION}

image:
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH}

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	rm -rf tbot
	docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}