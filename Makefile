
# Image URL to use all building/pushing image targets
BOOTSTRAP_IMG ?= ghcr.io/devigned/cluster-api-k3s/bootstrap-controller:v0.1.3

# Image URL to use all building/pushing image targets
CONTROLPLANE_IMG ?= ghcr.io/devigned/cluster-api-k3s/controlplane-controller:v0.1.3


# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:trivialVersions=true"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

CONTROLLER_GEN = $(shell pwd)/bin/controller-gen
.PHONY: controller-gen
controller-gen: ## Download controller-gen locally if necessary.
	$(call go-get-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen@v0.7.0)

KUSTOMIZE = $(shell pwd)/bin/kustomize
.PHONY: kustomize
kustomize: ## Download kustomize locally if necessary.
	$(call go-get-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v3@v3.8.7)

ENVTEST = $(shell pwd)/bin/setup-envtest
.PHONY: envtest
envtest: ## Download envtest-setup locally if necessary.
	$(call go-get-tool,$(ENVTEST),sigs.k8s.io/controller-runtime/tools/setup-envtest@latest)


all-bootstrap: manager-bootstrap

# Run tests
test-bootstrap: generate-bootstrap fmt vet manifests-bootstrap
	go test ./... -coverprofile cover.out

# Build manager binary
manager-bootstrap: generate-bootstrap fmt vet
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o bin/manager bootstrap/main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
run-bootstrap: generate-bootstrap fmt vet manifests-bootstrap
	go run ./bootstrap/main.go

# Install CRDs into a cluster
install-bootstrap: manifests-bootstrap
	$(KUSTOMIZE) build bootstrap/config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall-bootstrap: manifests-bootstrap
	$(KUSTOMIZE) build bootstrap/config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy-bootstrap: manifests-bootstrap
	cd bootstrap/config/manager && $(KUSTOMIZE) edit set image controller=${BOOTSTRAP_IMG}
	$(KUSTOMIZE) build bootstrap/config/default | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests-bootstrap: controller-gen
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=bootstrap/config/crd/bases output:rbac:dir=bootstrap/config/rbac

release-bootstrap: manifests-bootstrap
	mkdir -p out
	cd bootstrap/config/manager && $(KUSTOMIZE) edit set image controller=${BOOTSTRAP_IMG}
	$(KUSTOMIZE) build bootstrap/config/default > out/bootstrap-components.yaml

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Generate code
generate-bootstrap: controller-gen
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

# Build the docker image
docker-build-bootstrap: manager-bootstrap
	docker build . -t ${BOOTSTRAP_IMG}

# Push the docker image
docker-push-bootstrap:
	docker push ${BOOTSTRAP_IMG}


all-controlplane: manager-controlplane

# Run tests
test-controlplane: generate-controlplane fmt vet manifests-controlplane
	go test ./... -coverprofile cover.out

# Build manager binary
manager-controlplane: generate-controlplane fmt vet
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o bin/manager controlplane/main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
run-controlplane: generate-controlplane fmt vet manifests-controlplane
	go run ./controlplane/main.go

# Install CRDs into a cluster
install-controlplane: manifests-controlplane
	$(KUSTOMIZE) build controlplane/config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall-controlplane: manifests-controlplane
	$(KUSTOMIZE) build controlplane/config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy-controlplane: manifests-controlplane
	cd controlplane/config/manager && $(KUSTOMIZE) edit set image controller=${CONTROLPLANE_IMG}
	$(KUSTOMIZE) build controlplane/config/default | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests-controlplane: controller-gen
	$(CONTROLLER_GEN) rbac:roleName=manager-role webhook crd paths="./..." output:crd:artifacts:config=controlplane/config/crd/bases output:rbac:dir=bootstrap/config/rbac

release-controlplane: manifests-controlplane
	mkdir -p out
	cd controlplane/config/manager && $(KUSTOMIZE) edit set image controller=${CONTROLPLANE_IMG}
	$(KUSTOMIZE) build controlplane/config/default > out/control-plane-components.yaml

generate-controlplane: controller-gen
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

# Build the docker image
docker-build-controlplane: manager-controlplane
	docker build . -t ${CONTROLPLANE_IMG}

# Push the docker image
docker-push-controlplane:
	docker push ${CONTROLPLANE_IMG}

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
echo "PROJECT_DIR $(PROJECT_DIR)" ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef
