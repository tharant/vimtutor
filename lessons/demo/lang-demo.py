"""Python playground for Lesson 12 (needs :CocInstall coc-pyright).

The TODO markers below also feed Lesson 6's quickfix demo.
"""


def add(a: int, b: int) -> int:
    """TODO: hover over this docstring with K."""
    return a + b


def main(argv):
    print("python demo:", add(2, 3), argv)
    # TODO: gr on add() above -- references from the language server
    return 0


if __name__ == "__main__":
    raise SystemExit(main(None))
