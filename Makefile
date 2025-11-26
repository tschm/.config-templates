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
.PHONY: install-uv install install-task clean test marimo marimushka book fmt deptry docs help all

UV_INSTALL_DIR := ./bin
MARIMO_FOLDER := book/marimo
TESTS_FOLDER := tests
SOURCE_FOLDER := src

export UV_NO_MODIFY_PATH := 1
export UV_VENV_CLEAR = 1

##@ Bootstrap
install-uv: ## ensure uv/uvx is installed
	# Ensure the ${UV_INSTALL_DIR} folder exists
	@mkdir -p ${UV_INSTALL_DIR}

	# Install uv/uvx only if they are not already present
	@if [ -x "${UV_INSTALL_DIR}/uv" ] && [ -x "${UV_INSTALL_DIR}/uvx" ]; then \
	  printf "${BLUE}[INFO] uv and uvx already installed in ${UV_INSTALL_DIR}, skipping.${RESET}\n"; \
	else \
	  printf "${BLUE}[INFO] Installing uv and uvx...${RESET}\n"; \
	  if ! curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR="${UV_INSTALL_DIR}" sh >/dev/null 2>&1; then \
	    printf "${RED}[ERROR] Failed to install uv${RESET}\n"; \
	    exit 1; \
	  fi; \
	fi

install: install-uv ## install
	# Create the virtual environment only if it doesn't exist
	@if [ ! -d ".venv" ]; then \
	  ./bin/uv venv --python 3.12 || { printf "${RED}[ERROR] Failed to create virtual environment${RESET}\n"; exit 1; }; \
	else \
	  printf "${BLUE}[INFO] Using existing virtual environment at .venv, skipping creation${RESET}\n"; \
	fi

	# Check if there is requirements.txt file in the tests folder
	@if [ -f "tests/requirements.txt" ]; then \
	  ./bin/uv pip install -r tests/requirements.txt || { printf "${RED}[ERROR] Failed to install test requirements${RESET}\n"; exit 1; }; \
	fi

	# Install the dependencies from pyproject.toml (if it exists)
	@if [ -f "pyproject.toml" ]; then \
	  printf "${BLUE}[INFO] Installing dependencies${RESET}\n"; \
	  ./bin/uv sync --all-extras --frozen || { printf "${RED}[ERROR] Failed to install dependencies${RESET}\n"; exit 1; }; \
	else \
	  printf "${YELLOW}[WARN] No pyproject.toml found, skipping install${RESET}\n"; \
	fi


clean: install-uv ## clean
	@printf "${BLUE}Cleaning project...${RESET}\n"
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
test: install ## run all tests
	@if [ -d ${SOURCE_FOLDER} ] && [ -d ${TESTS_FOLDER} ]; then \
	  ./bin/uv pip install pytest pytest-cov pytest-html; \
	  mkdir -p _tests/html-coverage _tests/html-report; \
	  ./bin/uv run pytest ${TESTS_FOLDER} --cov=${SOURCE_FOLDER} --cov-report=term --cov-report=html:_tests/html-coverage --html=_tests/html-report/report.html; \
	else \
	  printf "${YELLOW}[WARN] Source folder ${SOURCE_FOLDER} or tests folder ${TESTS_FOLDER} not found, skipping tests${RESET}\n"; \
	fi

docs: install-uv ## create documentation with pdoc
	@if [ -d ${SOURCE_FOLDER} ]; then \
	  ./bin/uv pip install pdoc; \
	  ./bin/uv run pdoc -o _pdoc ${SOURCE_FOLDER}/*; \
	else \
	  printf "${YELLOW}[WARN] Source folder ${SOURCE_FOLDER} not found, skipping docs${RESET}\n"; \
	fi


marimo: install-uv ## fire up Marimo server
	@if [ ! -d "${MARIMO_FOLDER}" ]; then \
	  printf " ${YELLOW}[WARN] Marimo folder '${MARIMO_FOLDER}' not found, skipping start${RESET}\n"; \
	else \
	  ./bin/uv pip install marimo; \
	  ./bin/uv sync --all-extras; \
	  ./bin/uv run marimo edit "${MARIMO_FOLDER}"; \
	fi

marimushka: install ## export Marimo notebooks to HTML
	@printf "${BLUE}[INFO] Exporting notebooks from ${MARIMO_FOLDER}...${RESET}\n"
	@if [ ! -d "${MARIMO_FOLDER}" ]; then \
	  printf "${YELLOW}[WARN] Directory '${MARIMO_FOLDER}' does not exist. Skipping marimushka.${RESET}\n"; \
	else \
	  ./bin/uv pip install marimo; \
	  mkdir -p _marimushka; \
	  set -- "${MARIMO_FOLDER}"/*.py; \
	  if [ "$$1" = "${MARIMO_FOLDER}/*.py" ]; then \
	    printf "${YELLOW}[WARN] No Python files found in '${MARIMO_FOLDER}'.${RESET}\n"; \
	    echo "<html><head><title>Marimo Notebooks</title></head><body><h1>Marimo Notebooks</h1><p>No notebooks found.</p></body></html>" > _marimushka/index.html; \
	  else \
	    py_files=$$(printf "%s " "$$@"); \
	    printf "${BLUE}[INFO] Found Python files: %s${RESET}\n" "$$py_files"; \
	    for py_file in "$$@"; do \
	      printf " ${BLUE}[INFO] Processing %s...${RESET}\n" "$$py_file"; \
	      rel_path=$$(echo "$$py_file" | sed "s|^${MARIMO_FOLDER}/||"); \
	      dir_path=$$(dirname "$$rel_path"); \
	      base_name=$$(basename "$$rel_path" .py); \
	      mkdir -p "_marimushka/$$dir_path"; \
	      out_html="_marimushka/$$dir_path/$$base_name.html"; \
	      : # Ensure non-interactive overwrite: remove existing output file if present; \
	      rm -f "$$out_html"; \
	      if grep -q "^# /// script" "$$py_file"; then \
	        printf " ${BLUE}[INFO] Script header detected, using --sandbox flag...${RESET}\n"; \
	        ./bin/uvx marimo export html --sandbox --include-code --output "$$out_html" "$$py_file"; \
	      else \
	        printf " ${BLUE}[INFO] No script header detected, using standard export...${RESET}\n"; \
	        ./bin/uv run marimo export html --include-code --output "$$out_html" "$$py_file"; \
	      fi; \
	    done; \
	    echo "<html><head><title>Marimo Notebooks</title></head><body><h1>Marimo Notebooks</h1><ul>" > _marimushka/index.html; \
	    find _marimushka -name "*.html" -not -path "*index.html" | sort | while read html_file; do \
	      rel_path=$$(echo "$$html_file" | sed "s|^_marimushka/||"); \
	      name=$$(basename "$$rel_path" .html); \
	      echo "<li><a href=\"$$rel_path\">$$name</a></li>" >> _marimushka/index.html; \
	    done; \
	    echo "</ul></body></html>" >> _marimushka/index.html; \
	    touch _marimushka/.nojekyll; \
	  fi; \
	fi

##@ Documentation
book: test docs marimushka ## compile the companion book
	@printf "${BLUE}[INFO] Building combined documentation...${RESET}\n"
	@printf "${BLUE}[INFO] Ensuring jq is installed...${RESET}\n"
	@if ! command -v jq >/dev/null 2>&1; then \
	  if command -v apt-get >/dev/null 2>&1; then \
	    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi; \
	    $$SUDO apt-get update && $$SUDO apt-get install -y jq || true; \
	  elif command -v apk >/dev/null 2>&1; then \
	    apk add --no-cache jq || true; \
	  elif command -v dnf >/dev/null 2>&1; then \
	    dnf install -y jq || true; \
	  elif command -v brew >/dev/null 2>&1; then \
	    brew install jq || true; \
	  else \
	    printf "${YELLOW}[WARN] Could not install jq automatically. Proceeding, but book task may have limited functionality.${RESET}\n"; \
	  fi; \
	fi
	@printf "${BLUE}[INFO] Delete the _book folder...${RESET}\n"
	@rm -rf _book
	@printf "${BLUE}[INFO] Create empty _book folder...${RESET}\n"
	@mkdir -p _book
	@touch _book/links.json
	@printf "${BLUE}[INFO] Copy API docs...${RESET}\n"
	@if [ -f _pdoc/index.html ]; then \
	  mkdir -p _book/pdoc; \
	  cp -r _pdoc/* _book/pdoc; \
	  echo '{"API": "./pdoc/index.html"}' > _book/links.json; \
	else \
	  echo '{}' > _book/links.json; \
	fi
	@printf "${BLUE}[INFO] Copy coverage report...${RESET}\n"
	@if [ -f _tests/html-coverage/index.html ]; then \
	  mkdir -p _book/tests/html-coverage; \
	  cp -r _tests/html-coverage/* _book/tests/html-coverage; \
	  jq '. + {"Coverage": "./tests/html-coverage/index.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json; \
	else \
	  printf "${YELLOW}[WARN] No coverage report found or directory is empty${RESET}\n"; \
	fi
	@printf "${BLUE}[INFO] Copy test report...${RESET}\n"
	@if [ -f _tests/html-report/report.html ]; then \
	  mkdir -p _book/tests/html-report; \
	  cp -r _tests/html-report/* _book/tests/html-report; \
	  jq '. + {"Test Report": "./tests/html-report/report.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json; \
	else \
	  printf "${YELLOW}[WARN] No test report found or directory is empty${RESET}\n"; \
	fi
	@printf "${BLUE}[INFO] Copy notebooks...${RESET}\n"
	@if [ -f _marimushka/index.html ]; then \
	  mkdir -p _book/marimushka; \
	  cp -r _marimushka/* _book/marimushka; \
	  jq '. + {"Notebooks": "./marimushka/index.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json; \
	  printf "${BLUE}[INFO] Copied notebooks from ${MARIMO_FOLDER} to _book/marimushka${RESET}\n"; \
	else \
	  printf "${YELLOW}[WARN] No notebooks found or directory is empty${RESET}\n"; \
	fi
	@printf "${BLUE}[INFO] Generated links.json:${RESET}\n"
	@cat _book/links.json
	@./bin/uvx minibook --title "${BOOK_TITLE}" --subtitle "${BOOK_SUBTITLE}" --links "$$(jq -c . _book/links.json)" --output "_book"
	@touch "_book/.nojekyll"

fmt: install-uv ## check the pre-commit hooks and the linting
	@./bin/uvx pre-commit run --all-files

deptry: install-uv ## run deptry if pyproject.toml exists
	@if [ -f "pyproject.toml" ]; then \
	  ./bin/uvx deptry "${SOURCE_FOLDER}"; \
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
