# 🛠️ Config Templates

[![CI Status](https://github.com/tschm/.config-templates/workflows/CI/badge.svg)](https://github.com/tschm/config-templates/actions)
[![Release](https://github.com/tschm/.config-templates/workflows/Release%20Workflow/badge.svg)](https://github.com/tschm/config-templates/actions)

A collection of reusable configuration templates for modern Python projects.
Save time and maintain consistency across your projects with these
pre-configured templates.

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

#### GitHub Actions

In your GitHub Actions workflow, add an installation step:

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

#### GitLab CI/CD

In your GitLab CI/CD pipeline, add an installation step:

```yaml
# Install Task
- curl -sL https://taskfile.dev/install.sh | sh
- mv ./bin/task /usr/local/bin/task
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
name: Sync Config Templates

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday at midnight
  workflow_dispatch:  # Allow manual triggering

permissions:
  contents: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync Config Templates
        uses: tschm/.config-templates@main

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.PAT_TOKEN }}
          branch: sync/update-configs
          title: 'chore: sync configuration templates'
          commit-message: 'chore: sync config files from config-templates'
          body: |
            This PR updates configuration files from the
            [config-templates](https://github.com/tschm/.config-templates)
            repository.
```

This action will:
1. Download the latest templates from this repository
2. Copy them to your project
3. Create a pull request with the changes (if any)

### Using GitLab CI/CD Template

You can automatically sync these configuration templates into your GitLab project using the CI/CD template provided in this repository:

```yaml
# .gitlab-ci.yml
include:
  - remote: 'https://gitlab.com/tschm/config-templates/-/raw/main/.gitlab/ci-templates/sync-config-templates.yml'

# Define a job that extends the template
sync-config-templates:
  extends: .sync-config-templates
  variables:
    # Optional: override default branch name
    BRANCH_NAME: 'sync/update-configs'
    # Optional: override default commit message
    COMMIT_MESSAGE: 'chore: sync config files from config-templates'
  # Run manually from GitLab UI or on schedule
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
    - if: '$CI_PIPELINE_SOURCE == "web"'
      when: manual
```

To set up scheduled runs, go to CI/CD > Schedules in your GitLab project and create a new schedule.

This template will:
1. Download the latest templates from this repository
2. Copy them to your project
3. Create a branch with the changes
4. Optionally create a merge request if GITLAB_API_TOKEN is provided

## 📚 Documentation

The repository includes several documentation components:

- 📖 **API Documentation** - Generated with pdoc
- 📊 **Test Reports** - HTML test reports with coverage
- 📓 **Marimo Notebooks** - Interactive documentation

Build the complete documentation book:

```bash
task docs:book
```

## 🖥️ Dev Container Compatibility

This repository includes a template **Dev Container** configuration for seamless development experience in both **VS Code** and **GitHub Codespaces**.

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

Dev containers launched locally via VS code are configured with SSH agent forwarding to enable seamless Git operations:

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
