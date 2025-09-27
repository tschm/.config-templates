# 🛠️ Config Templates

[![CI Status](https://github.com/tschm/.config-templates/workflows/CI/badge.svg)](https://github.com/tschm/.config-templates/actions)
[![Release](https://github.com/tschm/.config-templates/workflows/Release%20Workflow/badge.svg)](https://github.com/tschm/.config-templates/actions)

A collection of reusable configuration templates
for modern Python projects.
Save time and maintain consistency across your projects
with these
pre-configured templates.

> Last updated: September 27, 2025

## ✨ Features

- 📦 **Task-based Workflows** - Organized task definitions using [Taskfile](https://taskfile.dev/)
- 🚀 **CI/CD Templates** - Ready-to-use GitHub Actions and GitLab CI workflows
- 🧪 **Testing Framework** - Comprehensive test setup with pytest
- 📚 **Documentation** - Automated documentation generation
- 🔍 **Code Quality** - Linting, formatting, and dependency checking
- 📝 **Editor Configuration** - Cross-platform .editorconfig for consistent coding style
- 📊 **Marimo Integration** - Interactive notebook support

## 🚀 Getting Started

### Prerequisites

All workflows rely on [Task](https://taskfile.dev/).
You can install it using one of the following methods:

```bash
brew install go-task/tap/go-task        # macOS
sudo snap install task --classic        # Ubuntu (Snap)
```

### Installation

```bash
# Clone the repository
git clone https://github.com/tschm/config-templates.git
cd config-templates

# Install dependencies (assuming Task is installed)
task build:install
```

## 📋 Available Tasks

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

## 📁 Available Templates

This repository includes the following configuration templates:

- **Taskfile.yml** - Main task runner configuration
- **taskfiles/** - Task definitions organized by category
  - **build.yml** - Tasks for dependency management and building
  - **cleanup.yml** - Tasks for cleaning up generated files
  - **docs.yml** - Tasks for documentation generation
  - **quality.yml** - Tasks for code quality checks
- **ruff.toml** - Configuration for the Ruff linter and formatter
- **.devcontainer/** - Development container configuration
- **.github/workflows/** - GitHub Actions workflow templates
- **Makefile** - Simple make commands for common operations

## 🧩 Usage Examples

You can inject the templates into your project
using one of the methods described below.

### Manual Copy

Copy the desired configuration files to your project:

```bash
# Example: Copy GitHub workflow files
mkdir -p .github/workflows
cp config-templates/.github/workflows/ci.yml .github/workflows/
```

### Using Jebel Quant's [Sync Template Action](https://github.com/marketplace/actions/sync-template)

You can automatically sync these configuration
templates into your GitHub repositories using
the Jebel Quant action:

```yaml
name: Sync Templates

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday at midnight
  workflow_dispatch:     # Allow manual triggering

permissions:
  contents: write
  pull-requests: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Template
        id: sync
        uses: jebel-quant/sync_template@v0.3.1
        with:
          token: ${{ secrets.PAT_TOKEN }}
          source: ".github/template.yml"
          branch: "template-updates"
          commit-message: "chore: sync template files"
```

This workflow will:

1. Download the latest templates based on your template.yml configuration
2. Copy them to your project
3. Create a pull request with the changes (if any)

**Note:** You need to create a `.github/template.yml` file in your repository that specifies 
which templates to sync. This file should list the configuration files you want to include from this repository. 
Example template.yml:

```yaml
template-repository: "tschm/.config-templates"
template-branch: "main"
include: |
    .github
    taskfiles
    tests
    .editorconfig
    .gitignore
    .pre-commit-config.yaml
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    Makefile
    ruff.toml
    Taskfile.yml
```

## 🖥️ Dev Container Compatibility

This repository includes a
template **Dev Container** configuration
for seamless development experience in
both **VS Code** and **GitHub Codespaces**.

### What's Configured

The `.devcontainer` setup provides:

- 🐍 **Python 3.13** runtime environment
- 🔧 **UV Package Manager** - Fast Python package installer and resolver
- ⚡ **Task CLI** - For running project workflows
- 🧪 **Pre-commit Hooks** - Automated code quality checks
- 📊 **Marimo Integration** - Interactive notebook support with VS Code extension
- 🔍 **Python Development Tools** - Pylance, Python extension, and optimized settings
- 🚀 **Port Forwarding** - Port 8080 for development servers
- 🔐 **SSH Agent Forwarding** - Full Git functionality with your host SSH keys

### Usage

#### In VS Code

1. Install the "Dev Containers" extension
2. Open the repository in VS Code
3. Click "Reopen in Container" when prompted
4. The environment will automatically set up with all dependencies

#### In GitHub Codespaces

1. Navigate to the repository on GitHub
2. Click the green "Code" button
3. Select "Codespaces" tab
4. Click "Create codespace on main" (or your branch)
5. Your development environment will be ready in minutes

The dev container automatically runs the initialization script that:

- Installs UV package manager
- Sets up Task CLI
- Configures the Python virtual environment
- Installs project dependencies
- Sets up pre-commit hooks

### VS Code Dev Container SSH Agent Forwarding

Dev containers launched locally via VS code
are configured with SSH agent forwarding
to enable seamless Git operations:

- **Mounts your SSH directory** - Your `~/.ssh` folder is mounted into the container
- **Forwards SSH agent** - Your host's SSH agent is available inside the container
- **Enables Git operations** - Push, pull, and clone using your existing SSH keys
- **Works transparently** - No additional setup required in VS Code dev containers

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
