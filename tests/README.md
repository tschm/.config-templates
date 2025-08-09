# Makefile Tests

This directory contains pytest unit tests for the project's Makefile.

## Overview

The tests in this directory verify that the Makefile is correctly
implemented and that all targets behave as expected. 
These tests are designed to be run with pytest and provide 
a way to ensure that changes to the Makefile don't break 
existing functionality.

## Test Files

- `test_docs.py`: Tests that validate code examples in the project documentation
- `test_makefile.py`: Tests that validate Makefile targets and their behavior

## Running the Tests

To run the tests, use the following command from the project root:

```bash
make test
```

Or to run the tests directly with pytest:

```bash
uv run pytest tests/
```

To run only the Makefile tests:

```bash
uv run pytest tests/test_makefile.py
```

## Test Categories

The Makefile tests are organized into the following categories:

### Target Existence Tests

These tests verify that all expected targets exist in the Makefile:

- `test_help_target_exists`
- `test_uv_target_exists`
- `test_install_target_exists`
- `test_fmt_target_exists`
- `test_lint_target_exists`
- `test_deptry_target_exists`
- `test_test_target_exists`
- `test_build_target_exists`
- `test_docs_target_exists`
- `test_marimushka_target_exists`
- `test_book_target_exists`
- `test_clean_target_exists`
- `test_check_target_exists`
- `test_marimo_target_exists`

### Target Behavior Tests

These tests verify that targets behave as expected:

- `test_install_target_checks_pyproject_toml`: Verifies that the install target checks for pyproject.toml
- `test_test_target_creates_readme_if_missing`: Verifies that the test target creates README.md if missing
- `test_build_target_checks_pyproject_toml`: Verifies that the build target checks for pyproject.toml
- `test_docs_target_checks_pyproject_toml`: Verifies that the docs target checks for pyproject.toml
- `test_marimo_target_checks_directory_exists`: Verifies that the marimo target checks if the directory exists
- `test_check_target_runs_lint_and_test`: Verifies that the check target runs lint and test

### Makefile Structure Tests

These tests verify the overall structure of the Makefile:

- `test_phony_targets_declared`: Verifies that all targets are declared as .PHONY
- `test_default_goal_is_help`: Verifies that the default goal is help
- `test_makefile_has_sections`: Verifies that the Makefile has sections

## Adding New Tests

To add a new test for a Makefile target:

1. Add a new test function to `test_makefile.py`
2. Use the `makefile_content` fixture to access the Makefile content
3. Write assertions to verify the target's existence and behavior
4. Run the tests to ensure they pass

Example:

```python
def test_new_target_exists(makefile_content: str):
    """Test that the 'new_target' target exists in the Makefile."""
    assert re.search(r"new_target:.*?##.*?Description", makefile_content), "New target not found"
```

## Maintenance

When making changes to the Makefile, make sure to update the tests accordingly. If you add a new target, add a corresponding test to verify its existence and behavior.