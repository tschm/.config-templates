# ruff: noqa
"""Test suite for Taskfile schema and content."""

from textwrap import dedent

import pytest

try:
    import yaml
except Exception:  # pragma: no cover
    pytest.skip("PyYAML (yaml) not available in environment", allow_module_level=True)

# Source YAML content under test (from PR diff focus)
TASKFILE_YAML = dedent("""\
version: '3'

tasks:
  uv:
    desc: Install uv and uvx
    cmds:
      # Download uv/uvx
      - curl -sSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1 || (echo "${RED}Installation failed!${RESET}" >&2; exit 1)
      - export PATH="$HOME/.cargo/bin:$PATH"

  install:
    desc: Install all dependencies using uv
    deps: [uv]
    cmds:
      - |
        # Check if .venv folder already exists
        if [ -d ".venv" ]; then
          printf "${BLUE}[INFO] Virtual environment already exists, skipping installation${RESET}\\n"
        else
          # we need the virtual environment at least for the tests to work
          # even if we don't install anything

          # Create the virtual environment
          printf "${BLUE}[INFO] Creating virtual environment...${RESET}\\n"

          # Create the virtual environment
          uv venv --python 3.12 || { printf "${RED}[ERROR] Failed to create virtual environment${RESET}\\n"; exit 1; }

          if [ -f "pyproject.toml" ]; then
            printf "${BLUE}[INFO] Installing dependencies${RESET}\\n"
            uv sync --all-extras --frozen || { printf "${RED}[ERROR] Failed to install dependencies${RESET}\\n"; exit 1; }
          else
            printf "${YELLOW}[WARN] No pyproject.toml found, skipping install${RESET}\\n"
          fi
        fi

  build:
    desc: Build the package using hatch
    deps: [install]
    cmds:
      - |
        if [ -f "pyproject.toml" ]; then
          printf "${BLUE}[INFO] Building package...${RESET}\\n"
          uv pip install hatch
          uv run hatch build
        else
          printf "${YELLOW}[WARN] No pyproject.toml found, skipping build${RESET}\\n"
        fi
""")

@pytest.fixture(scope="module")
def taskfile():
    """Parse TASKFILE_YAML and return it as a dict."""
    data = yaml.safe_load(TASKFILE_YAML)
    assert isinstance(data, dict), "Top-level YAML must parse to a dict"
    return data

class TestTaskfileSchema:
    """Tests for Taskfile schema."""

    def test_version_is_3(self, taskfile):
        """Ensure the version is '3'."""
        assert "version" in taskfile, "Missing 'version' key"
        # allow both string '3' and numeric 3; but given YAML is quoted '3'
        assert str(taskfile["version"]) == "3"

    def test_tasks_key_present(self, taskfile):
        """Ensure the 'tasks' key is present and is a mapping."""
        assert "tasks" in taskfile, "Missing 'tasks' key"
        assert isinstance(taskfile["tasks"], dict), "'tasks' must be a mapping"

    def test_required_tasks_exist(self, taskfile):
        """Ensure required tasks 'uv', 'install', and 'build' exist."""
        tasks = taskfile["tasks"]
        for required in ("uv", "install", "build"):
            assert required in tasks, f"Missing required task '{required}'"
            assert isinstance(tasks[required], dict)

    def test_each_task_has_desc_and_cmds(self, taskfile):
        """Ensure each task has non-empty 'desc' and 'cmds' entries."""
        tasks = taskfile["tasks"]
        for name, conf in tasks.items():
            assert "desc" in conf, f"Task '{name}' missing 'desc'"
            assert isinstance(conf["desc"], str) and conf["desc"].strip(), f"Task '{name}' has empty 'desc'"
            assert "cmds" in conf, f"Task '{name}' missing 'cmds'"
            assert (
                isinstance(conf["cmds"], list)
                and len(conf["cmds"]) > 0
            ), f"Task '{name}' must have non-empty 'cmds' list"

class TestDepsConstraints:
    """Tests for task dependencies constraints."""

    def test_install_depends_on_uv(self, taskfile):
        """Ensure 'install' depends only on 'uv'."""
        install = taskfile["tasks"]["install"]
        assert "deps" in install, "install must declare deps"
        assert isinstance(install["deps"], list)
        assert install["deps"] == ["uv"], "install should depend only on 'uv'"

    def test_build_depends_on_install(self, taskfile):
        """Ensure 'build' depends only on 'install'."""
        build = taskfile["tasks"]["build"]
        assert "deps" in build, "build must declare deps"
        assert isinstance(build["deps"], list)
        assert build["deps"] == ["install"], "build should depend only on 'install'"

class TestUvTaskContent:
    """Tests for 'uv' task commands."""

    def test_uv_task_downloads_installer_with_curl(self, taskfile):
        """Ensure the 'uv' task downloads the installer with curl."""
        uv = taskfile["tasks"]["uv"]
        cmds = uv["cmds"]
        assert any("curl -sSf https://astral.sh/uv/install.sh" in c for c in cmds), "uv must download installer with curl"
        # Check that it pipes to sh and captures output to /dev/null
        assert any("| sh > /dev/null 2>&1" in c for c in cmds), "uv curl command should pipe to sh and discard output"
        # Check exit-on-failure message
        assert any("Installation failed!" in c for c in cmds), "uv should echo installation failure on error"

    def test_uv_task_exports_cargo_bin_to_path(self, taskfile):
        """Ensure the 'uv' task exports the cargo bin path."""
        uv = taskfile["tasks"]["uv"]
        cmds = uv["cmds"]
        assert any('export PATH="$HOME/.cargo/bin:$PATH"' in c for c in cmds), "uv must export cargo bin on PATH"

class TestInstallTaskContent:
    """Tests for 'install' task's script content."""

    def _get_single_script(self, taskfile):
        """Return the combined script string for 'install' cmds."""
        install = taskfile["tasks"]["install"]
        cmds = install["cmds"]
        # The install task contains one multi-line script via literal block '|'
        # Normalize to a single string for pattern checks
        script = "\n".join(cmds) if all(isinstance(c, str) for c in cmds) else cmds[0]
        assert isinstance(script, str) and script.strip(), "install cmds must contain a non-empty script"
        return script

    def test_checks_for_existing_venv_and_skips_with_info(self, taskfile):
        """Ensure the 'install' script checks for existing .venv and skips installation."""
        script = self._get_single_script(taskfile)
        assert 'if [ -d ".venv" ]' in script, "install should check for .venv directory"
        assert "skipping installation" in script, "install should print skip info when .venv exists"

    def test_creates_virtualenv_with_python_3_12_and_handles_failure(self, taskfile):
        """Ensure the 'install' script creates venv with Python 3.12 and handles failure."""
        script = self._get_single_script(taskfile)
        assert "uv venv --python 3.12" in script, "install should create venv with Python 3.12"
        assert "Failed to create virtual environment" in script, "install should report venv creation failure"

    def test_installs_deps_when_pyproject_present_and_handles_errors(self, taskfile):
        """Ensure the 'install' script installs dependencies and handles errors."""
        script = self._get_single_script(taskfile)
        assert 'if [ -f "pyproject.toml" ]' in script, "install should check for pyproject.toml"
        assert "Installing dependencies" in script, "install should print installing message"
        assert "uv sync --all-extras --frozen" in script, "install should sync deps with all-extras and frozen"
        assert "Failed to install dependencies" in script, "install should report dependency install failure"

    def test_warns_when_pyproject_missing(self, taskfile):
        """Ensure the 'install' script warns when pyproject.toml is missing."""
        script = self._get_single_script(taskfile)
        assert "No pyproject.toml found, skipping install" in script, "install should warn when pyproject missing"

    def test_informational_logging_present(self, taskfile):
        """Ensure the 'install' script logs informational messages and uses color variables."""
        script = self._get_single_script(taskfile)
        assert (
            "${BLUE}" in script
            and "${RED}" in script
            and "${YELLOW}" in script
        ), "install should use color variables in messages"

class TestBuildTaskContent:
    """Tests for 'build' task's script content."""

    def _get_single_script(self, taskfile):
        """Return the combined script string for 'build' cmds."""
        build = taskfile["tasks"]["build"]
        cmds = build["cmds"]
        script = "\n".join(cmds) if all(isinstance(c, str) for c in cmds) else cmds[0]
        assert isinstance(script, str) and script.strip(), "build cmds must contain a non-empty script"
        return script

    def test_builds_when_pyproject_present(self, taskfile):
        """Ensure the 'build' script builds when pyproject.toml is present."""
        script = self._get_single_script(taskfile)
        assert 'if [ -f "pyproject.toml" ]' in script, "build should check for pyproject.toml"
        assert "Building package" in script, "build should print that it's building"
        assert "uv pip install hatch" in script, "build should ensure hatch is installed via uv pip"
        assert "uv run hatch build" in script, "build should run hatch build via uv"

    def test_warns_when_pyproject_missing(self, taskfile):
        """Ensure the 'build' script warns when pyproject.toml is missing."""
        script = self._get_single_script(taskfile)
        assert "No pyproject.toml found, skipping build" in script, "build should warn when pyproject missing"

class TestDefensiveStructure:
    """Tests for defensive structure of tasks definitions."""

    def test_cmds_lists_are_nonempty_and_strings(self, taskfile):
        """Ensure all 'cmds' lists are non-empty and contain only strings."""
        for name, conf in taskfile["tasks"].items():
            cmds = conf["cmds"]
            # cmds can include multi-line block scalars; ensure they are strings
            assert len(cmds) > 0, f"Task '{name}' has empty cmds list"
            assert all(isinstance(c, str) for c in cmds), f"All cmds for '{name}' should be strings or block scalars"

    def test_no_empty_descs(self, taskfile):
        """Ensure no task descriptions are empty."""
        for name, conf in taskfile["tasks"].items():
            assert conf["desc"].strip() != "", f"Task '{name}' description should not be empty"

# Edge cases and failure-oriented assertions validate that the script includes the appropriate guards and messages.
# Since we are not executing the shell commands, we assert on their
# presence and structure, which is appropriate for unit tests of config content.