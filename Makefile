APP=$(subst .git,,$(shell basename $(shell git remote get-url origin)))
REGISTRY=ghcr.io
REPOSITORY=evgenpavlyuchek/tbot
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

build: format get #Unix-like system requared
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o tbot -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=${VERSION}-${TARGETOS}-${TARGETARCH}

image:
	docker build . -t ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH} --build-arg TARGETOS=${TARGETOS}

push:
	docker push ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}

all: build image push
	sed -i -E 's/(tag:\s*)"([^"]*)"/\1"${VERSION}"/' helm/values.yaml
	sed -i -E 's/(appVersion:\s*)"([^"]*)"/\1"${VERSION}"/' helm/Chart.yaml

all1:
	git commit -am "test"
	git push

clean:
	rm -rf tbot
	docker rmi ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}

#################################	helm	###########################

hinstall:
	helm install tbot ./helm --set secret.secretValue=${TELE_TOKEN}
# --set image.tag=${VERSION} --set image.os=${TARGETOS} --set image.arch=${TARGETARCH}

htemplate:
	helm template tbot ./helm --set secret.secretValue=${TELE_TOKEN}
# --set image.tag=${VERSION} --set image.os=${TARGETOS} --set image.arch=${TARGETARCH}

########################	local k3d + argocd	########################

TELE_TOKEN=$(shell grep -oP 'TELE_TOKEN\s*=\s*"\K[^"]+' ../makevars.tfvars)
TARGET_BRANCHE=develop

deploy:
	k3d cluster create test
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD pods to start..."
	@sleep 10  # wait 10 sec
	@kubectl wait --for=condition=Ready pod -n argocd --all --timeout=300s
	@echo "ArgoCD pods are ready!"
	@echo "\
apiVersion: argoproj.io/v1alpha1\n\
kind: Application\n\
metadata:\n\
  name: tbot\n\
  namespace: argocd\n\
  finalizers:\n\
    - resources-finalizer.argocd.argoproj.io\n\
spec:\n\
  destination:\n\
    name: ''\n\
    namespace: default\n\
    server: 'https://kubernetes.default.svc'\n\
  source:\n\
    path: helm\n\
    repoURL: 'https://github.com/EvgenPavlyuchek/tbot.git'\n\
    targetRevision: ${TARGET_BRANCHE}\n\
    helm:\n\
      valueFiles:\n\
        - values.yaml\n\
      parameters:\n\
        - name: secret.secretValue\n\
          value: \"${TELE_TOKEN}\"\n\
  project: default\n\
  syncPolicy:\n\
    syncOptions:\n\
      - CreateNamespace=true\n\
    automated:\n\
      prune: true\n\
      selfHeal: true" > temp.yaml
	# sed -i 's/targetRevision: HEAD/targetRevision: develop/' ./temp.yaml && kubectl apply -f ./temp.yaml
	kubectl apply -f ./temp.yaml
	rm temp.yaml
	@echo "=================================================="
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	@echo "=================================================="
	kubectl port-forward svc/argocd-server -n argocd 8080:443

port:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	kubectl port-forward svc/argocd-server -n argocd 8080:443

check:
	argocd login localhost:8080 --username admin --password "$(shell kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" --insecure
	argocd app list
	@echo "=================================================="
	argocd app get tbot

dep: #without argocd
	docker build . -t ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH} --build-arg TARGETOS=${TARGETOS}
	docker push ${REGISTRY}/${REPOSITORY}:${VERSION}-${TARGETOS}-${TARGETARCH}
	k3d cluster create test || true
	@echo "secret:\n\
  secretValue: ${TELE_TOKEN}" > temp.yaml
	helm install tbot ./helm --values ./temp.yaml --set image.tag=${VERSION} --set image.os=${TARGETOS} --set image.arch=${TARGETARCH}
	rm temp.yaml
	kubectl get po -w

del:
	k3d cluster delete test

# target:
# 	@echo "Value of VARIABLE: ${VARIABLE}"
# make target VARIABLE=new_value

########################	terraform + flux	########################

# ENV environment variable needs to be set to gke or kind
# ENV=gke
# ENV=gke make tapply
# ENV=kind make tapply

tinit:
	terraform -chdir=terraform/${ENV}/ init

tupgrade:
	terraform -chdir=terraform/${ENV}/ init -upgrade

tvalidate:
	terraform -chdir=terraform/${ENV}/ fmt -recursive
	terraform -chdir=terraform/${ENV}/ validate

tplan:
	# terraform -chdir=terraform/${ENV}/ workspace new ${ENV} || true
	# terraform -chdir=terraform/${ENV}/ workspace select ${ENV}
	terraform -chdir=terraform/${ENV}/ validate
	terraform -chdir=terraform/${ENV}/ plan -var-file=../../../makevars.tfvars

tcost:
    ifeq ($(ENV), gke)
		cd ./terraform/${ENV}/
		infracost breakdown --path .
		cd ../..
    else ifeq ($(ENV), login)
		infracost auth login
    else
		@echo "Not gcloud"
    endif

tapply:
	@echo "####################################################"
	# @echo "Press Enter to continue..."
	# @read _
	# terraform -chdir=terraform/${ENV}/ workspace new ${ENV} || true
	# terraform -chdir=terraform/${ENV}/ workspace select ${ENV}
	terraform -chdir=terraform/${ENV}/ apply -var-file=../../../makevars.tfvars --auto-approve
    ifeq ($(ENV), gke)
		gcloud container clusters get-credentials main --zone us-central1-c --project=$(shell grep -oP 'GOOGLE_PROJECT\s*=\s*"\K[^"]+' ../makevars.tfvars)
		kubectl get po --all-namespaces -w
    else ifeq ($(ENV), kind)
		kubectl get po --all-namespaces -w
    else
		kubectl get po --all-namespaces -w
    endif

tdestroy:
	@echo "####################################################"
	# @echo "Press Enter to continue..."
	# @read _
	# @-terraform -chdir=terraform/${ENV}/ workspace new ${ENV}
	# terraform -chdir=terraform/${ENV}/ workspace select ${ENV} 
	terraform -chdir=terraform/${ENV}/ destroy -var-file=../../../makevars.tfvars --auto-approve
	make github_del_repo

tdestroy_target:
    ifeq ($(ENV), gke)
		terraform -chdir=terraform/${ENV}/ destroy -target="module.flux_bootstrap" -target="module.gke_cluster" -target="github_repository"
    else
		terraform -chdir=terraform/${ENV}/ destroy -target="module.flux_bootstrap_kind" -target="module.kind_cluster" -target="github_repository"
    endif
	
github_del_repo:
	@GITHUB_OWNER=$$(grep -oP 'GITHUB_OWNER\s*=\s*"\K[^"]+' ../makevars.tfvars); \
	GH_TOKEN=$(shell grep -oP 'TF_VAR_GITHUB_TOKEN_DEL_REPO\s*=\s*"\K[^"]+' ../makevars.tfvars); \
	gh repo delete $${GITHUB_OWNER}/flux-gitops --confirm

########################	   gcloud  	  ########################

gcloud_del:
	gsutil -m rm -r gs://test-gc-cloud/**
	gcloud container clusters delete main --project=$(shell grep -oP 'GOOGLE_PROJECT\s*=\s*"\K[^"]+' ../makevars.tfvars) --zone=us-central1-c

gcloud_pods:
	gcloud container clusters get-credentials main --zone us-central1-c --project=$(shell grep -oP 'GOOGLE_PROJECT\s*=\s*"\K[^"]+' ../makevars.tfvars)
	kubectl get po --all-namespaces -w

########################	gitlab_runner	########################
# make gitlab_runner r=

gitlab_runner:
    ifeq ($(r), run)
		docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
    else ifeq ($(r), register)
		docker run --rm -it -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register
    else ifeq ($(r), cp)
		sudo cp ../config.toml /srv/gitlab-runner/config/config.toml
    else ifeq ($(r), config)
		sudo nano /srv/gitlab-runner/config/config.toml
    else ifeq ($(r), restart)
		docker restart gitlab-runner
    else ifeq ($(r), stop)
		docker stop gitlab-runner
    else ifeq ($(r), rm)
		docker rm -f gitlab-runner
		docker ps -a
    else ifeq ($(r), prune)
		docker system prune --all
		docker volume prune
    else
		docker ps -a
    endif

########################	jenkins 	########################

jenkins:
	kind create cluster --name jenkins
	helm repo add jenkinsci https://charts.jenkins.io/
	helm repo update
	helm install jenkins jenkinsci/jenkins
	@echo "Waiting for jenkins pods to start..."
	@sleep 10  # wait 10 sec
	@kubectl wait --for=condition=Ready pod/jenkins-0 --timeout=300s
	@echo "jenkins pods are ready!"
	@echo "####################################################"
	@echo "admin"
	@kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
	@kubectl port-forward svc/jenkins 8080:8080

jenkins-d:
	kind delete cluster --name jenkins

############	pre-commit github hook + gitleaks 	##############

gl-on:
	git config hooks.gitleaks true

gl-off:
	git config hooks.gitleaks false

gl-onn:
	git config hooks.whitespace true

gl-offf:
	git config hooks.whitespace false

gl-cp:
	cp ./scripts/pre-commit.sh ./.git/hooks/pre-commit

gl-run:
	./scripts/pre-commit.sh

############        	OTEL monitoring           ##############

compose_up:
	docker-compose -f otel/docker-compose.yaml up

compose_down:
	docker-compose -f otel/docker-compose.yaml down

compose_upd:
	docker-compose -f otel/docker-compose.yaml up -d

compose_rebuild:
	docker-compose -f otel/docker-compose.yaml rebuild

############        	OTEL monitoring           ##############