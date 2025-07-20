# Makefile for shadow package

# Default shell
SHELL := /bin/bash

# Test runner
TEST_RUNNER := tests/run-tests.sh

# Bats executable
BATS := bats

# Colors
NO_COLOR ?=
ifeq ($(NO_COLOR),)
    GREEN := \033[0;32m
    YELLOW := \033[1;33m
    RED := \033[0;31m
    NC := \033[0m
else
    GREEN :=
    YELLOW :=
    RED :=
    NC :=
endif

.PHONY: all test test-unit test-integration test-verbose help install-deps lint

# Default target
all: help

# Run all tests
test:
	@echo -e "$(GREEN)Running shadow package tests...$(NC)"
	@if command -v $(BATS) >/dev/null 2>&1; then \
		./$(TEST_RUNNER); \
	else \
		echo -e "$(RED)Error: bats not found. Run 'make install-deps' to install dependencies.$(NC)"; \
		exit 1; \
	fi

# Run only unit tests
test-unit:
	@echo -e "$(GREEN)Running unit tests...$(NC)"
	@./$(TEST_RUNNER) --unit

# Run only integration tests
test-integration:
	@echo -e "$(GREEN)Running integration tests...$(NC)"
	@./$(TEST_RUNNER) --integration

# Run tests with verbose output
test-verbose:
	@echo -e "$(GREEN)Running tests with verbose output...$(NC)"
	@./$(TEST_RUNNER) --verbose

# Install test dependencies
install-deps:
	@echo -e "$(YELLOW)Installing test dependencies...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing bats-core via Homebrew..."; \
		brew install bats-core; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Installing bats via apt..."; \
		sudo apt-get update && sudo apt-get install -y bats; \
	else \
		echo -e "$(RED)Please install bats-core manually: https://github.com/bats-core/bats-core$(NC)"; \
		exit 1; \
	fi

# Lint shell scripts
lint:
	@echo -e "$(GREEN)Linting shell scripts...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -o -name "shadow*" -type f | grep -v ".git" | while read -r file; do \
			if [[ -x "$$file" ]] && head -1 "$$file" | grep -q '^#!/.*sh'; then \
				echo "Checking $$file..."; \
				shellcheck "$$file" || exit 1; \
			fi; \
		done; \
		echo -e "$(GREEN)All scripts passed shellcheck!$(NC)"; \
	else \
		echo -e "$(YELLOW)Warning: shellcheck not found. Install it for shell script linting.$(NC)"; \
	fi

# Show help
help:
	@echo "Shadow Package Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make test             - Run all tests"
	@echo "  make test-unit        - Run only unit tests"
	@echo "  make test-integration - Run only integration tests"
	@echo "  make test-verbose     - Run tests with verbose output"
	@echo "  make install-deps     - Install test dependencies (bats)"
	@echo "  make lint             - Lint shell scripts with shellcheck"
	@echo "  make help             - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  NO_COLOR=1           - Disable colored output"