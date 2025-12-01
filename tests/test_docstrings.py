"""Tests for module docstrings using doctest.

Automatically discovers all packages under `src/`
and runs doctests for each.
"""

from __future__ import annotations

import doctest
import importlib
import sys
import warnings
from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Return the repository root (directory containing pyproject.toml)."""
    root = Path(__file__).parent.parent
    assert (root / "pyproject.toml").is_file()
    return root


def _iter_modules_from_path(package_path: Path):
    """Recursively find all Python modules in a directory."""
    for path in package_path.rglob("*.py"):
        if path.name == "__init__.py":
            module_path = path.parent.relative_to(package_path.parent)
        else:
            module_path = path.relative_to(package_path.parent).with_suffix("")

        # Convert path to module name
        module_name = str(module_path).replace("/", ".")

        try:
            yield importlib.import_module(module_name)
        except ImportError as e:
            warnings.warn(f"Could not import {module_name}: {e}")


def test_doctests(project_root: Path):
    """Run doctests for each package directory under src/."""
    src_path = project_root / "src"

    if not src_path.exists():
        warnings.warn(f"Source directory not found: {src_path}")
        return

    # Add src to sys.path to allow imports
    if str(src_path.parent) not in sys.path:
        sys.path.insert(0, str(src_path.parent))

    total_tests = 0
    total_failures = 0
    failed_modules = []

    # Find all packages in src
    for package_dir in src_path.iterdir():
        if package_dir.is_dir() and (package_dir / "__init__.py").exists():
            # Import the package
            package_name = package_dir.name
            try:
                modules = list(_iter_modules_from_path(package_dir))

                for module in modules:
                    results = doctest.testmod(
                        module,
                        verbose=False,
                        optionflags=(doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE),
                    )
                    total_tests += results.attempted

                    if results.failed:
                        total_failures += results.failed
                        failed_modules.append((module.__name__, results.failed, results.attempted))

            except ImportError as e:
                warnings.warn(f"Could not import package {package_name}: {e}")
                continue

    if failed_modules:
        formatted = "\n".join(f"  {name}: {failed}/{attempted} failed" for name, failed, attempted in failed_modules)
        msg = (
            f"Doctest summary: {total_tests} tests across {len(failed_modules)} module(s)\n"
            f"Failures: {total_failures}\n"
            f"Failed modules:\n{formatted}"
        )
        assert total_failures == 0, msg

    if total_tests == 0:
        warnings.warn("No doctests were found in any module", stacklevel=1)
