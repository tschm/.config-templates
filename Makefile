## Makefile for config-templates: developer tasks orchestrated via go-task
#
# This Makefile wraps the Taskfile.yml commands and provides a friendly
# `make help` index. Lines with `##` after a target are parsed into help text,
# and lines starting with `##@` create section headers in the help output.
#
# Colors for pretty output in help messages
BLUE := \033[36m
BOLD := \033[1m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m

# Default goal when running `make` with no target
.DEFAULT_GOAL := help

# Declare phony targets (they don't produce files)
.PHONY: install-task install clean test marimo book fmt deptry help all

UV_INSTALL_DIR := "./bin"
UV_NO_MODIFY_PATH := 1
MARIMO_FOLDER := "book/marimo"
TESTS_FOLDER := "tests"
SOURCE_FOLDER := "src"

##@ Bootstrap
install-task: ## ensure go-task (Taskfile) is installed
	@mkdir -p ${UV_INSTALL_DIR}

	@if [ ! -x "${UV_INSTALL_DIR}/task" ]; then \
		printf "$(BLUE)Installing go-task (Taskfile)$(RESET)\n"; \
		curl --location https://taskfile.dev/install.sh | sh -s -- -d -b ${UV_INSTALL_DIR}; \
	fi

	printf "${BLUE}[INFO] Installing uv and uvx...${RESET}\n"
	@if ! curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then \
	  printf "${RED}[ERROR] Failed to install uv${RESET}\n"; \
	  exit 1; \
	fi


install: install-task ## install
	@./bin/task build:install --silent

clean: install-task ## clean
	printf "${BLUE}Cleaning project...${RESET}\n"
	# do not clean .env files
	@git clean -d -X -f -e .env -e '.env.*'
	@rm -rf dist build *.egg-info .coverage .pytest_cache
	@printf "${BLUE}Removing local branches with no remote counterpart...${RESET}\n"
	@git fetch --prune
	@git branch -vv \
	  | grep ': gone]' \
	  | awk '{print $1}' \
	  | xargs -r git branch -D 2>/dev/null || true

##@ Development and Testing
test: install-task ## run all tests
	@./bin/uv pip install pytest pytest-cov pytest-html
	@mkdir -p _tests/html-coverage _tests/html-report
	@./bin/uv run pytest ${TESTS_FOLDER} --cov=${SOURCE_FOLDER} --cov-report=term --cov-report=html:_tests/html-coverage --html=_tests/html-report/report.html

marimo: install-task ## fire up Marimo server
	@if [ ! -d "${MARIMO_FOLDER}" ]; then \
	  printf " ${YELLOW}[WARN] Marimo folder '${MARIMO_FOLDER}' not found, skipping start${RESET}\n"; \
	else \
	  @./bin/uv sync --all-extras; \
	  @./bin/uv run marimo edit "${MARIMO_FOLDER}"; \
	fi


##@ Documentation
book: test ## compile the companion book
	@./bin/task docs:docs --silent
	@./bin/task docs:marimushka --silent
	@./bin/task docs:book --silent

fmt: install-task ## check the pre-commit hooks and the linting
	@./bin/uvx pre-commit run --all-files

deptry: install-task ## run deptry if pyproject.toml exists
	if [ -f "pyproject.toml" ]; then \
	  ./bin/uvx deptry ${SOURCE_FOLDER}; \
	else \
	  printf "${YELLOW} No pyproject.toml found, skipping deptry${RESET}\n"; \
	fi

all: fmt deptry test book ## Run everything
	echo "Run fmt, deptry, test and book"

##@ Meta
help: ## Display this help message
	+@printf "$(BOLD)Usage:$(RESET)\n"
	+@printf "  make $(BLUE)<target>$(RESET)\n\n"
	+@printf "$(BOLD)Targets:$(RESET)\n"
	+@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BOLD)%s$(RESET)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
