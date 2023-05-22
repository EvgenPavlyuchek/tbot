VERSION:
	VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

format:
	gofmt -s -w ./
build:
	go build -v -o tbot -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=${VERSION}'