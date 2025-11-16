"""Simple arithmetic helpers for documentation examples and tests.

This module intentionally keeps utilities minimal. It currently exposes a
single function, `add`, used in examples and sanity checks.
"""


def add(a, b):
    """Return the sum of a and b.

    Args:
        a: First addend.
        b: Second addend.

    Returns:
        The arithmetic sum of ``a`` and ``b``.
    """
    return a + b
