"""Shared pytest fixtures for the test suite.

Provides the 'root' fixture that returns the repository root as a pathlib.Path,
enabling tests to locate files and scripts relative to the project root.
"""
import logging
import pathlib

import pytest


@pytest.fixture(scope="session")
def root():
    """Return the repository root directory as a pathlib.Path.

    Used by tests to locate files and scripts relative to the project root.
    """
    return pathlib.Path(__file__).parent.parent


@pytest.fixture(scope="session")
def logger():
    logger = logging.getLogger("tests")
    logger.setLevel(logging.DEBUG)

    # add handler for console output once per session
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
        logger.addHandler(handler)

    return logger
