"""Marimo app notebook demonstrating the config_templates.add function.

This module is an auto-generated Marimo notebook. It imports the add helper
from the config_templates package and evaluates a few simple cells. The module is used
for documentation/book integration and can be launched with `python -m marimo`
or by running this file directly.
"""

# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "marimo",
#     "config-templates"
# ]
# ///

import marimo

__generated_with = "0.17.7"
app = marimo.App(width="medium")


@app.cell
def _():
    from config-templates import add

    return (add,)


@app.cell
def _(add):
    add(2, 3)
    return


@app.cell
def _(add):
    add(3, 4)
    return


if __name__ == "__main__":
    app.run()
