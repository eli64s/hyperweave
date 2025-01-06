SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

DOCS_DIR := docs
PYPROJECT := pyproject.toml
TARGET := hyperweave tests
TARGET_TEST := tests
PYTHON_VERSION := 3.11

# -- Clean

.PHONY: clean
clean: ## Clean build and virtual environment directories
	@echo -e "\n► Cleaning up project environment and directories..."
	-rm -rf dist/ .venv/ build/ *.egg-info/
	-find . -name "__pycache__" -type d -exec rm -rf {} +
	-find . -name "*.pyc" -type f -exec rm -f {} +


# -- Dependencies

.PHONY: build
build: ## Build the distribution package using uv
	uv build
	uv pip install dist/splitme_ai-0.1.0-py3-none-any.whl

.PHONY: install
install: ## Install all dependencies from pyproject.toml
	uv sync --dev --group test --group docs --group lint --all-extras

.PHONY: lock
lock: ## Lock dependencies declared in pyproject.toml
	uv pip compile pyproject.toml --all-extras

.PHONY: requirements
requirements: ## Generate requirements files from pyproject.toml
	uv pip compile pyproject.toml -o requirements.txtiu
	uv pip compile pyproject.toml --all-extras -o requirements-dev.txt

.PHONY: sync
sync: ## Sync environment with pyproject.toml
	uv sync --all-groups --dev

.PHONY: update
update: ## Update all dependencies from pyproject.toml
	uv lock --upgrade

.PHONY: venv
venv: ## Create a virtual environment
	uv venv --python $(PYTHON_VERSION)


# -- Format & Lint

.PHONY: format-toml
format-toml: ## Format TOML files using pyproject-fmt
	uvx --isolated pyproject-fmt $(TOML_FILE) --indent 4

.PHONY: format
format: ## Format Python files using Ruff
	@echo -e "\n► Running the Ruff formatter..."
	uvx --isolated ruff format $(TARGET) --config .ruff.toml

.PHONY: lint
lint: ## Lint Python files using Ruff
	@echo -e "\n ►Running the Ruff linter..."
	uvx --isolated ruff check $(TARGET) --fix --config .ruff.toml

.PHONY: format-and-lint
format-and-lint: format lint ## Format and lint Python files

# -- Documentation

.PHONY: docs
docs: ## Serve mintlify documentation locally
	cd $(DOCS_DIR) && npx mintlify dev --verbose


# -- Type Checking

.PHONY: typecheck-mypy
typecheck-mypy: ## Type-check Python files using MyPy
	uv run mypy $(TARGET)

.PHONY: typecheck-pyright
typecheck-pyright: ## Type-check Python files using Pyright
	uv run pyright $(TARGET)


# -- Testing

.PHONY: test
test: ## Run tests using Pytest
	uv run pytest $(TARGET_TEST) --config-file $(PYPROJECT)


# -- Utilities

.PHONY: run
run: ## Run the app
	uv run src/hyperweave/app.py

.PHONY: help
help: ## Display this help
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "; printf "\033[1m%-20s %-50s\033[0m\n", "Target", "Description"; \
	              printf "%-20s %-50s\n", "------", "-----------";} \
	      /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %-50s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
