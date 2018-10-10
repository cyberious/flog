PROJECT_NAME := "flog"
PKGS := $(shell go list ./... | grep -v /vendor)
PKG := "gitlab.com/cyberious/$(PROJECT_NAME)"
GO_FILES := $(shell find . -name '*.go' | grep -v /vendor/ | grep -v _test.go)

.PHONY: all dep release clean test coverage coverhtml lint

all: release

race: dep ## Run data race detector
	@go test -race -short ${PKGS}

msan: dep ## Run memory sanitizer
	@go test -msan -short ${PKGS}

coverage: ## Generate global code coverage report
	@mkdir -p _cover
	@go test ./... -cover
	@go test ./... -coverprofile _cover/cover.out
	@go tool cover -func _cover/cover.out

coverhtml: ## Generate global code coverage report in HTML
	@mkdir -p _cover
	@go test ./... -cover
	@go test ./... -coverprofile _cover/cover.out
	@go tool cover -html=_cover/cover.out -o _cover/cover.html

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


BIN_DIR := $(GOPATH)/bin
GOMETALINTER := $(BIN_DIR)/gometalinter

$(GOMETALINTER):
					go get -u github.com/alecthomas/gometalinter
					gometalinter --install &> /dev/null

.PHONY: lint
lint: deps $(GOMETALINTER)
					gometalinter ./... --vendor

BINARY := flog
VERSION ?= vlatest
PLATFORMS := linux darwin
os = $(word 1, $@)

.PHONY: $(PLATFORMS)
$(PLATFORMS): deps
					mkdir -p _release
					GOOS=$(os) GOARCH=amd64 go build -o _release/$(BINARY)-$(VERSION)-$(os)-amd64

.PHONY: dep
dep:
ifeq ($(shell command -v dep 2> /dev/null),)
	go get -u -v github.com/golang/dep/cmd/dep
endif

.PHONY: deps
deps: dep
	@dep ensure -v

test: deps
	@go test $(PKGS)

.PHONY: release
release: linux darwin

.PHONY: clean
clean:
	rm -rf _cover
	rm -rf vendor
	rm -rf _release

.PHONY: docker
docker:
					docker build . -t cyberious/flog
