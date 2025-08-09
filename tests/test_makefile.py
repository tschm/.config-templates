"""Tests for validating Makefile tasks.

This file is part of the tschm/.config-templates repository
(https://github.com/tschm/.config-templates).

This module contains pytest unit tests for individual Makefile tasks.
Each test uses mocked outputs to validate the expected behavior of make targets.
"""

import re
from pathlib import Path

import pytest


@pytest.fixture
def project_root() -> Path:
    """Fixture that provides the project root directory.

    Returns:
        Path: The path to the project root directory.
    """
    # Get the directory of the current file
    current_dir = Path(__file__).parent
    # Go up one level to get the project root
    return current_dir.parent


@pytest.fixture
def makefile_content(project_root: Path) -> str:
    """Fixture that provides the content of the Makefile.

    Args:
        project_root: Path to the project root directory

    Returns:
        str: The content of the Makefile
    """
    try:
        with open(project_root / "Makefile", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        pytest.fail(f"Failed to read Makefile: {e}")


def test_help_target_exists(makefile_content: str):
    """Test that the 'help' target exists in the Makefile."""
    assert re.search(r"help:.*?##.*?Display this help message", makefile_content), "Help target not found"


def test_uv_target_exists(makefile_content: str):
    """Test that the 'uv' target exists in the Makefile."""
    assert re.search(r"uv:.*?##.*?Install uv", makefile_content), "UV target not found"


def test_install_target_exists(makefile_content: str):
    """Test that the 'install' target exists in the Makefile."""
    assert re.search(r"install:.*?##.*?Install", makefile_content), "Install target not found"


def test_fmt_target_exists(makefile_content: str):
    """Test that the 'fmt' target exists in the Makefile."""
    assert re.search(r"fmt:.*?##.*?Run code formatters", makefile_content), "Format target not found"


def test_lint_target_exists(makefile_content: str):
    """Test that the 'lint' target exists in the Makefile."""
    assert re.search(r"lint:.*?##.*?Run", makefile_content), "Lint target not found"


def test_deptry_target_exists(makefile_content: str):
    """Test that the 'deptry' target exists in the Makefile."""
    assert re.search(r"deptry:.*?##.*?Run deptry", makefile_content), "Deptry target not found"


def test_test_target_exists(makefile_content: str):
    """Test that the 'test' target exists in the Makefile."""
    assert re.search(r"test:.*?##.*?[Rr]un.*?tests", makefile_content), "Test target not found"


def test_build_target_exists(makefile_content: str):
    """Test that the 'build' target exists in the Makefile."""
    assert re.search(r"build:.*?##.*?Build", makefile_content), "Build target not found"


def test_docs_target_exists(makefile_content: str):
    """Test that the 'docs' target exists in the Makefile."""
    assert re.search(r"docs:.*?##.*?Build documentation", makefile_content), "Docs target not found"


def test_marimushka_target_exists(makefile_content: str):
    """Test that the 'marimushka' target exists in the Makefile."""
    assert re.search(r"marimushka:.*?##.*?Export Marimo notebooks", makefile_content), "Marimushka target not found"


def test_book_target_exists(makefile_content: str):
    """Test that the 'book' target exists in the Makefile."""
    assert re.search(r"book:.*?##.*?[Bb]uild.*?book", makefile_content), "Book target not found"


def test_clean_target_exists(makefile_content: str):
    """Test that the 'clean' target exists in the Makefile."""
    assert re.search(r"clean:.*?##.*?Clean", makefile_content), "Clean target not found"


def test_check_target_exists(makefile_content: str):
    """Test that the 'check' target exists in the Makefile."""
    assert re.search(r"check:.*?##.*?Run all checks", makefile_content), "Check target not found"


def test_marimo_target_exists(makefile_content: str):
    """Test that the 'marimo' target exists in the Makefile."""
    assert re.search(r"marimo:.*?##.*?Start a Marimo server", makefile_content), "Marimo target not found"


def test_install_target_checks_pyproject_toml(makefile_content: str):
    """Test that the 'install' target checks for pyproject.toml."""
    assert 'if [ -f "pyproject.toml" ]' in makefile_content, "Install target should check for pyproject.toml"
    assert "No pyproject.toml found, skipping" in makefile_content, (
        "Install target should handle missing pyproject.toml"
    )


def test_test_target_creates_readme_if_missing(makefile_content: str):
    """Test that the 'test' target creates README.md if missing."""
    assert 'if [ ! -f "README.md" ]' in makefile_content, "Test target should check for README.md"
    assert 'echo "# Hello World" > README.md' in makefile_content, "Test target should create README.md if missing"


def test_build_target_checks_pyproject_toml(makefile_content: str):
    """Test that the 'build' target checks for pyproject.toml."""
    assert 'if [ -f "pyproject.toml" ]' in makefile_content, "Build target should check for pyproject.toml"
    assert "No pyproject.toml found, skipping build" in makefile_content, (
        "Build target should handle missing pyproject.toml"
    )


def test_docs_target_checks_pyproject_toml(makefile_content: str):
    """Test that the 'docs' target checks for pyproject.toml."""
    assert 'if [ -f "pyproject.toml" ]' in makefile_content, "Docs target should check for pyproject.toml"
    assert "No pyproject.toml found, skipping docs" in makefile_content, (
        "Docs target should handle missing pyproject.toml"
    )


def test_marimo_target_checks_directory_exists(makefile_content: str):
    """Test that the 'marimo' target checks if the directory exists."""
    assert 'if [ ! -d "$(MARIMO_FOLDER)" ]' in makefile_content, "Marimo target should check if directory exists"
    # The exact command might vary, so we'll check for the concept rather than exact syntax
    assert "not found" in makefile_content and "MARIMO_FOLDER" in makefile_content, (
        "Marimo target should handle missing directory"
    )


def test_check_target_runs_lint_and_test(makefile_content: str):
    """Test that the 'check' target runs lint and test."""
    check_pattern = re.search(r"check:.*?lint.*?test", makefile_content, re.DOTALL)
    assert check_pattern, "Check target should run lint and test"


def test_phony_targets_declared(makefile_content: str):
    """Test that .PHONY is declared for all targets."""
    phony_line = re.search(r"\.PHONY:.*", makefile_content)
    assert phony_line, ".PHONY declaration not found"

    # Extract the list of phony targets
    phony_targets = phony_line.group(0).split(":")[1].strip().split()

    # Check that all important targets are declared as phony
    important_targets = [
        "help",
        "uv",
        "install",
        "fmt",
        "lint",
        "deptry",
        "test",
        "build",
        "docs",
        "marimushka",
        "book",
        "clean",
        "check",
        "marimo",
    ]

    for target in important_targets:
        assert target in phony_targets, f"Target '{target}' should be declared as .PHONY"


def test_default_goal_is_help(makefile_content: str):
    """Test that the default goal is help."""
    assert ".DEFAULT_GOAL := help" in makefile_content, "Default goal should be help"


def test_makefile_has_sections(makefile_content: str):
    """Test that the Makefile has sections."""
    sections = re.findall(r"##@\s+([A-Za-z ]+)", makefile_content)
    assert len(sections) > 0, "Makefile should have sections"

    # Check for important sections
    important_sections = ["Development", "Code Quality", "Testing", "Building", "Documentation"]
    for section in important_sections:
        assert any(section in s for s in sections), f"Makefile should have a '{section}' section"
