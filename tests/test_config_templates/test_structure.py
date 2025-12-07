"""Tests for the root pytest fixture that yields the repository root Path.

This module ensures the fixture resolves to the true project root and that
expected files/directories exist, enabling other tests to locate resources
reliably.
"""

from pathlib import Path


class TestRootFixture:
    """Tests for the root fixture that provides repository root path."""

    def test_root_returns_pathlib_path(self, root):
        """Root fixture should return a pathlib.Path object."""
        assert isinstance(root, Path)

    def test_root_points_to_repository_root(self, root):
        """Root fixture should point to the actual repository root."""
        assert (root / "pyproject.toml").exists()
        assert (root / "README.md").exists()
        assert (root / ".github").is_dir()

    def test_root_is_absolute_path(self, root):
        """Root fixture should return an absolute path."""
        assert root.is_absolute()

    def test_root_resolves_correctly_from_nested_location(self, root):
        """Root should correctly resolve to repository root from tests/test_config_templates/."""
        conftest_path = root / "tests" / "test_config_templates" / "conftest.py"
        assert conftest_path.exists()

    def test_root_contains_expected_directories(self, root):
        """Root should contain all expected project directories."""
        expected_dirs = [".github", "src", "tests", "book"]
        for dirname in expected_dirs:
            assert (root / dirname).exists(), f"Expected directory {dirname} not found"

    def test_root_contains_expected_files(self, root):
        """Root should contain all expected configuration files."""
        expected_files = [
            "pyproject.toml",
            "README.md",
            "Makefile",
            "ruff.toml",
            "pytest.ini",
            ".gitignore",
            ".editorconfig",
        ]
        for filename in expected_files:
            assert (root / filename).exists(), f"Expected file {filename} not found"

    def test_root_can_locate_github_scripts(self, root):
        """Root should allow locating GitHub scripts."""
        scripts_dir = root / ".github" / "scripts"
        assert scripts_dir.exists()
        assert (scripts_dir / "release.sh").exists()
        assert (scripts_dir / "bump.sh").exists()
        assert (scripts_dir / "sync.sh").exists()

    def test_root_can_locate_source_files(self, root):
        """Root should allow locating source files."""
        src_dir = root / "src"
        assert src_dir.exists()
        config_dir = src_dir / "config"
        assert config_dir.exists()
        assert (config_dir / "__init__.py").exists()
        assert (config_dir / "add.py").exists()

    def test_root_uses_pathlib_module(self, root):
        """Root fixture should use pathlib.Path from pathlib module."""
        import pathlib

        assert isinstance(root, pathlib.Path)

    def test_root_supports_pathlib_operations(self, root):
        """Root should support all standard pathlib operations."""
        assert callable(root.exists)
        assert callable(root.is_dir)
        assert callable(root.resolve)
        assert callable(root.absolute)
        assert callable(root.iterdir)

        child = root / "README.md"
        assert isinstance(child, Path)
        assert child.parent == root
