# 🛠️ Config Templates

[![CI Status](https://github.com/tschm/.config-templates/workflows/CI/badge.svg)](https://github.com/tschm/config-templates/actions)
[![Release](https://github.com/tschm/.config-templates/workflows/Release%20Workflow/badge.svg)](https://github.com/tschm/config-templates/actions)

A collection of reusable configuration templates for modern Python projects. 
Save time and maintain consistency across your projects with these 
pre-configured templates.

## ✨ Features

- 📦 **Task-based Workflows** - Organized task definitions using [Taskfile](https://taskfile.dev/)
- 🚀 **CI/CD Templates** - Ready-to-use GitHub Actions workflows
- 🧪 **Testing Framework** - Comprehensive test setup with pytest
- 📚 **Documentation** - Automated documentation generation
- 🔍 **Code Quality** - Linting, formatting, and dependency checking
- 📊 **Marimo Integration** - Interactive notebook support

## 🚀 Getting Started

### Prerequisites

All workflows rely on [Task](https://taskfile.dev/). 
You can install it using one of the following methods:
  
```bash
brew install go-task/tap/go-task        # macOS
sudo snap install task --classic        # Ubuntu (Snap)
```

In your CI workflow, add an installation step:  

```yaml 
name: Install Go Task CLI
run: |
  if ! command -v task &> /dev/null; then
    curl -sSL https://raw.githubusercontent.com/go-task/task/v3/install.sh | sh
  fi
```

or

```yaml
name: Install Go Task CLI
uses: arduino/setup-task@v2
with:
  version: 3.x
  # optional but recommended to avoid API rate limiting
  repo-token: ${{ secrets.GITHUB_TOKEN }}
```

### Installation

```bash
# Clone the repository
git clone https://github.com/tschm/config-templates.git
cd config-templates

# Install dependencies
task build:install
```

## 📋 Available Tasks

We recommend using [Task](https://taskfile.dev/) to run the available tasks.
Run `task --list-all` to see all available tasks:

```
* build:build:      Build the package using hatch
* build:install:    Install all dependencies using uv
* build:uv:         Install uv and uvx
* cleanup:clean:    Clean generated files and directories
* docs:book:        Build the companion book with test results and notebooks
* docs:docs:        Build documentation using pdoc
* docs:marimo:      Start a Marimo server
* docs:marimushka:  Export Marimo notebooks to HTML
* docs:test:        Run all tests
* quality:check:    Run all code quality checks
* quality:deptry:   Check for dependency issues
* quality:fmt:      Format code using Ruff
* quality:lint:     Run pre-commit hooks
```

We also provide a small [Makefile](Makefile) for convenience.

## 🧩 Usage Examples

We recommend injecting the templates into your project using the 
[GitHub Action](https://github.com/tschm/config-templates/actions)
provided in this repository.

### Manual Copy

Copy the desired configuration files to your project:

```bash
# Example: Copy GitHub workflow files
mkdir -p .github/workflows
cp config-templates/.github/workflows/ci.yml .github/workflows/

# Example: Copy Taskfile
cp config-templates/Taskfile.yml .
```

### Using GitHub Action

You can automatically sync these configuration 
templates into your project using the GitHub Action provided 
in this repository:

```yaml
# .github/workflows/sync-configs.yml
name: Sync Config Templates

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday at midnight
  workflow_dispatch:  # Allow manual triggering

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Sync Config Templates
        uses: tschm/config-templates@main
        
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          branch: sync/update-configs
          title: 'chore: sync configuration templates'
          commit-message: 'chore: sync config files from config-templates'
          body: |
            This PR updates configuration files from the 
            [config-templates](https://github.com/tschm/.config-templates)
            repository.
            
            - Automated PR created by GitHub Actions
```

This action will:
1. Download the latest templates from this repository
2. Copy them to your project
3. Create a pull request with the changes (if any)

## 📚 Documentation

The repository includes several documentation components:

- 📖 **API Documentation** - Generated with pdoc
- 📊 **Test Reports** - HTML test reports with coverage
- 📓 **Marimo Notebooks** - Interactive documentation

Build the complete documentation book:

```bash
task docs:book
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Taskfile](https://taskfile.dev/) - For the amazing task runner
- [GitHub Actions](https://github.com/features/actions) - For CI/CD capabilities
- [Marimo](https://marimo.io/) - For interactive notebooks
- [UV](https://github.com/astral-sh/uv) - For fast Python package operations