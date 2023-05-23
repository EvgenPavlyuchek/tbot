# APP=$(shell basename $(shell git remote get-url origin))  #  $(APP)    shell dpkg --print-architecture
APP=$(subst .git,,$(shell basename $(shell git remote get-url origin)))
REGISTRY=terr
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=linux
TARGETARCH=arm64

format:
	gofmt -s -w ./

lint:
	golint

test:
	go test -v

get:
	go get

build: format get
	CGO_ENABLED=0 GOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o tbot -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=${VERSION}

image:
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	rm -rf tbot