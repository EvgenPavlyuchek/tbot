# APP=$(shell basename $(shell git remote get-url origin))  #  $(APP)    shell dpkg --print-architecture
APP=$(subst .git,,$(shell basename $(shell git remote get-url origin)))
REGISTRY=ghcr.io
REPOSITORY=evgenpavlyuchek/tbot
# REGISTRY=terr
# REPOSITORY=tbot
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=linux
#linux darwin windows
TARGETARCH=amd64
#amd64 arm64 arm 386

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
	TARGETARCH = amd64
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
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o tbot -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=${VERSION}-${TARGETOS}-${TARGETARCH}

image:
	docker build . -t ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH} --build-arg TARGETOS=${TARGETOS}

push:
	docker push ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}

clean:
	rm -rf tbot
	docker rmi ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}

deploy: #local k3d+github
	k3d cluster create test
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@sleep 10  # wait 10 sec
	@echo "Waiting for ArgoCD pods to start..."
	@kubectl wait --for=condition=Ready pod -n argocd --all --timeout=300s
	@echo "ArgoCD pods are ready!"
	# kubectl apply -f ../maketbotargocd.yaml
	sed -i 's/targetRevision: HEAD/targetRevision: develop/' ../maketbotargocd.yaml && kubectl apply -f ../maketbotargocd.yaml
	@echo "=================================================="
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	@echo "=================================================="
	kubectl port-forward svc/argocd-server -n argocd 8080:443

port: #local
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	kubectl port-forward svc/argocd-server -n argocd 8080:443

check: #local k3d
	argocd login localhost:8080 --username admin --password "$(shell kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" --insecure
	argocd app list
	@echo "=================================================="
	argocd app get tbot

dep: #local k3d
	docker build . -t ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH} --build-arg TARGETOS=${TARGETOS}
	docker push ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}
	k3d cluster create test || true
	helm install tbot ./helm --values ../maketokenvalue.yaml --set image.tag=${VERSION} --set image.os=${TARGETOS} --set image.arch=${TARGETARCH}

d: #local
	k3d cluster delete test

k: #local
	k3d cluster create test


# target:
# 	@echo "Value of MY_VARIABLE: $(MY_VARIABLE)"
# make target MY_VARIABLE=new_value
