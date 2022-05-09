# Build variables
VERSION ?= $(shell git describe --tags --always)
GOVERSION := $(shell go version | cut -d ' ' -f 3 | cut -d '.' -f 2)
GO_MODULE_NAME := github.com/sraphs/go-starter
REPOSITORY_URL := $(shell git remote get-url origin | sed -e 's|git@\(.*\):\(.*\)\.git|https://\1/\2|g')

# Go variables
GO      ?= go
GOOS    := $(shell $(GO) env GOOS)
GOARCH  := $(shell $(GO) env GOARCH)
GOHOST  := GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO)

LDFLAGS ?= "-s -w -X main.version=$(VERSION)"

.DEFAULT_GOAL := help

###############
##@ Development

.PHONY: init
init: ## Init environment
	@ $(MAKE) --no-print-directory log-$@
	go install golang.org/x/tools/cmd/stringer@latest
	go install github.com/git-chglog/git-chglog/cmd/git-chglog@latest

.PHONY: rename
rename: ## Rename Go module refactoring
	@ $(MAKE) --no-print-directory log-$@
	@echo "Enter new go module-name:" \
		&& read new_module_name \
		&& echo "new go module-name: '$${new_module_name}'" \
		&& echo -n "Are you sure? [y/N]" \
		&& read ans && [ $${ans:-N} = y ] \
		&& echo -n "Please wait..." \
		&& find . -type f -not -path '*/\.*' -exec sed -i "s|${GO_MODULE_NAME}|$${new_module_name}|g" {} \; \
		&& echo "new go module-name: '$${new_module_name}'!"

.PHONY: clean
clean: ## Clean workspace
	@ $(MAKE) --no-print-directory log-$@
	go clean

.PHONY: check 
check: test fmt vet lint ## Run tests and linters

.PHONY: test
test: ## Run tests
	@ $(MAKE) --no-print-directory log-$@
	@ $(MAKE) --no-print-directory log-$@
	go test -covermode atomic -coverprofile coverage.out ./...
	go tool cover -func=coverage.out


.PHONY: fmt
fmt:  ## Run gofmt linter
	@ $(MAKE) --no-print-directory log-$@
	@if [ "`gofmt -l -s *.go | tee /dev/stderr`" ]; then \
		echo "^ improperly formatted go files" && echo && exit 1; \
	fi \

.PHONY: vet
vet: ## Run go vet linter
	@ $(MAKE) --no-print-directory log-$@
	@if [ "`go vet | tee /dev/stderr`" ]; then \
		echo "^ go vet errors!" && echo && exit 1; \
	fi

.PHONY: lint
lint: ## Run golint linter
	@ $(MAKE) --no-print-directory log-$@
	@for d in `go list` ; do \
		if [ "`golint $$d | tee /dev/stderr`" ]; then \
			echo "^ golint errors!" && echo && exit 1; \
		fi \
	done

.PHONY: dev
dev: ## Dev
	@ $(MAKE) --no-print-directory log-$@
	CGO_ENABLED=0 $(GOHOST) run -ldflags=$(LDFLAGS) ./...

#########
##@ Build

.PHONY: build
build: ## Build
	@ $(MAKE) --no-print-directory log-$@
	CGO_ENABLED=0 $(GOHOST) build -ldflags=$(LDFLAGS) ./...

###########
##@ Release

.PHONY: changelog
changelog:  ## Generate changelog
	@ $(MAKE) --no-print-directory log-$@
	git-chglog --next-tag $(VERSION) --repository-url $(REPOSITORY_URL) -o CHANGELOG.md

.PHONY: release
release: changelog  ## Release a new tag
	@ $(MAKE) --no-print-directory log-$@
	git add CHANGELOG.md
	git commit -m "🚀chore: update changelog for $(VERSION)" 
	git tag $(VERSION)
	git push origin main $(VERSION)

########
##@ Help

.PHONY: help
help:   ## Display this help
	@awk \
		-v "col=\033[36m" -v "nocol=\033[0m" \
		' \
			BEGIN { \
				FS = ":.*##" ; \
				printf "Usage:\n  make %s<target>%s\n", col, nocol \
			} \
			/^[a-zA-Z_-]+:.*?##/ { \
				printf "  %s%-12s%s %s\n", col, $$1, nocol, $$2 \
			} \
			/^##@/ { \
				printf "\n%s%s%s\n", nocol, substr($$0, 5), nocol \
			} \
		' $(MAKEFILE_LIST)

log-%:
	@grep -h -E '^$*:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk \
			'BEGIN { \
				FS = ":.*?## " \
			}; \
			{ \
				printf "\033[36m==> %s\033[0m\n", $$2 \
			}'
