import marimo

__generated_with = "0.17.7"
app = marimo.App(width="medium")


@app.cell
def _():
    from config import add
    return (add,)


@app.cell
def _(add):
    add(2,3)
    return


@app.cell
def _(add):
    add(3, 4)
    return


if __name__ == "__main__":
    app.run()
