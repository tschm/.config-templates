"""Tests for module docstrings using doctest.

Automatically discovers all packages under `src/` and runs doctests for each.
"""

from __future__ import annotations

import doctest
import importlib
import pkgutil
import sys
import warnings
from collections.abc import Iterator
from pathlib import Path
from types import ModuleType


def _find_src_dir(start: Path) -> Path | None:
    """Find first package directory under src."""
    current = start.resolve()
    while True:
        src_root = current / "src"
        if src_root.is_dir():
            init_files = sorted(src_root.rglob("__init__.py"))
            return init_files[0].parent if init_files else src_root
        if current.parent == current:
            return None
        current = current.parent


def iter_modules(package_name: str | None = None) -> Iterator[ModuleType]:
    """Yield importable modules recursively from a given package or from src."""
    if package_name:
        pkg = importlib.import_module(package_name)
        if not hasattr(pkg, "__path__"):
            yield pkg
            return
        yield pkg
        for _, name, _ in pkgutil.walk_packages(pkg.__path__, prefix=package_name + "."):
            try:
                yield importlib.import_module(name)
            except ImportError:
                continue
        return

    # Auto-discover packages under src/
    src_or_pkg_dir = _find_src_dir(Path(__file__).parent)
    if src_or_pkg_dir is None:
        raise RuntimeError("Could not locate project 'src' directory")

    # Find the actual src root
    probe = src_or_pkg_dir
    while probe.name != "src" and probe.parent != probe:
        probe = probe.parent
    src_root = probe

    # Ensure import path
    src_root_str = str(src_root)
    if src_root_str not in sys.path:
        sys.path.insert(0, src_root_str)

    # If src/ directly contains packages
    if src_or_pkg_dir == src_root:
        for _, name, ispkg in pkgutil.iter_modules([src_root_str]):
            if not ispkg:
                continue
            pkg = importlib.import_module(name)
            yield pkg
            if hasattr(pkg, "__path__"):
                for _, subname, _ in pkgutil.walk_packages(pkg.__path__, prefix=name + "."):
                    try:
                        yield importlib.import_module(subname)
                    except ImportError:
                        continue
    else:
        # Example: src/cvx/risk
        base = src_or_pkg_dir.relative_to(src_root).as_posix().replace("/", ".")
        pkg = importlib.import_module(base)
        yield pkg
        if hasattr(pkg, "__path__"):
            for _, sub, _ in pkgutil.walk_packages(pkg.__path__, prefix=base + "."):
                try:
                    yield importlib.import_module(sub)
                except ImportError:
                    continue


def test_docstrings() -> None:
    """Run doctest over all discovered modules."""
    modules = list(iter_modules())

    total_tests = 0
    total_failures = 0
    failed_modules = []

    for module in modules:
        # Avoid crazy namespace imports (e.g., namespace packages with no file)
        if getattr(module, "__file__", None) is None:
            continue

        # Skip modules with empty/no docstring for speed
        if not (module.__doc__ and ">>> " in module.__doc__):
            # Still allow inline-function doctests inside the module
            pass

        results = doctest.testmod(
            module,
            verbose=False,
            optionflags=(doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE),
        )

        total_tests += results.attempted
        if results.failed:
            total_failures += results.failed
            failed_modules.append((module.__name__, results.failed, results.attempted))

    if failed_modules:
        formatted = "\n".join(f"  {name}: {failed}/{attempted} failed" for name, failed, attempted in failed_modules)
        msg = (
            f"Doctest summary: {total_tests} tests across {len(modules)} modules\n"
            f"Failures: {total_failures}\n"
            f"Failed modules:\n{formatted}"
        )
        assert total_failures == 0, msg

    if total_tests == 0:
        warnings.warn("No doctests were found", stacklevel=1)
