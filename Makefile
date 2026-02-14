.DEFAULT_GOAL := help
SHELL := /bin/bash

CHARTS := $(shell find charts -maxdepth 2 -name Chart.yaml -not -path '*/lib/*' | xargs -I{} dirname {})

.PHONY: help new build-deps lint template validate clean all

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

new: ## Scaffold a new service (make new SERVICE=redis)
ifndef SERVICE
	@echo "Usage: make new SERVICE=<name>"; exit 1
endif
	@python3 scripts/generate.py $(SERVICE)

build-deps: ## Build Helm dependencies
	@for chart in $(CHARTS); do helm dependency build $$chart 2>/dev/null || true; done

lint: build-deps ## Lint all charts
	@for chart in $(CHARTS); do helm lint $$chart --quiet; done

template: build-deps ## Render chart templates (dry-run)
	@for chart in $(CHARTS); do \
		echo "━━━ $$(basename $$chart) ━━━"; \
		helm template test-$$(basename $$chart) $$chart; \
	done

validate: ## Validate values against JSON schemas
	@for chart in $(CHARTS); do \
		schema="$$chart/values.schema.json"; values="$$chart/values.yaml"; \
		[ -f "$$schema" ] && [ -f "$$values" ] && npx --yes ajv-cli validate -s "$$schema" -d "$$values" 2>/dev/null; \
	done

clean: ## Clean build artifacts
	@rm -rf charts/*/charts charts/*/Chart.lock

all: lint validate ## Run all checks
