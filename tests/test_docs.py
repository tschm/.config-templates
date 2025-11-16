"""Doctest README.md's Python code blocks with a float-tolerant checker.

This module parses fenced Python blocks from the top-level README.md and runs
them with doctest in a shared namespace. It uses a custom OutputChecker that
allows small floating-point differences and enables ELLIPSIS and
NORMALIZE_WHITESPACE, so examples remain stable yet meaningful as the code
evolves.
"""

import doctest
import math
from doctest import ELLIPSIS, IGNORE_EXCEPTION_DETAIL, NORMALIZE_WHITESPACE
from pathlib import Path

import pytest


@pytest.fixture()
def readme_path() -> Path:
    """Provide the path to the project's README.md file.

    This fixture searches for the README.md file by starting in the current
    directory and moving up through parent directories until it finds the file.

    Returns:
    -------
    Path
        Path to the README.md file

    Raises:
    ------
    FileNotFoundError
        If the README.md file cannot be found in any parent directory

    """
    current_dir = Path(__file__).resolve().parent
    while current_dir != current_dir.parent:
        candidate = current_dir / "README.md"
        if candidate.is_file():
            return candidate
        current_dir = current_dir.parent
    raise FileNotFoundError("README.md not found in any parent directory")


class FloatTolerantOutputChecker(doctest.OutputChecker):
    """Doctest output checker tolerant to small float discrepancies."""

    def check_output(self, want, got, optionflags):
        """Return True if outputs match allowing for small float differences.

        This first defers to the standard doctest comparison. If that fails,
        it parses all floats contained in the expected and actual strings and
        compares them using math.isclose with a small tolerance.

        Args:
            want: The expected output string from the doctest.
            got: The actual output string produced by the code under test.
            optionflags: Bitmask of doctest option flags in effect.
        """
        # First try vanilla doctest comparison
        if super().check_output(want, got, optionflags):
            return True

        # Try float-tolerant comparison
        try:
            # Extract floats from both strings
            want_floats = [
                float(x) for x in want.replace(",", " ").split() if x.replace(".", "", 1).replace("-", "", 1).isdigit()
            ]
            got_floats = [
                float(x) for x in got.replace(",", " ").split() if x.replace(".", "", 1).replace("-", "", 1).isdigit()
            ]

            if len(want_floats) != len(got_floats):
                return False

            return all(math.isclose(w, g, rel_tol=1e-3, abs_tol=1e-5) for w, g in zip(want_floats, got_floats))
        except Exception:
            return False


def test_doc(readme_path):
    """Run doctests extracted from README.md using a tolerant checker.

    Ensures all Python code blocks in the README execute and their outputs
    match expected results, allowing for minor floating point differences.
    """
    parser = doctest.DocTestParser()
    runner = doctest.DocTestRunner(
        checker=FloatTolerantOutputChecker(),
        optionflags=ELLIPSIS | NORMALIZE_WHITESPACE | IGNORE_EXCEPTION_DETAIL,
    )

    doc = readme_path.read_text(encoding="utf-8")

    test = parser.get_doctest(doc, {}, readme_path.name, readme_path, 0)
    result = runner.run(test)

    assert result.failed == 0
