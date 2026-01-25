---
description: 'Python-specific best practices, type annotations, and uv virtual environment guidelines'
applyTo: '**/*.py, **/*.pyi'
---

# Python Coding Conventions

## Core Standards

Write concise, idiomatic code following **PEP 8** and **PEP 257**. Indent with 4 spaces and limit lines to 132 characters. Ensure
all functions have complete type annotations (using the `typing` module where necessary) and docstrings. Break complex logic into
manageable functions.

### Type Annotations and Documentation Example

```python
from typing import List, Optional

def process_data(values: List[float], limit: Optional[float] = None) -> List[float]:
    """
    Filter and transform a list of numerical values.

    Args:
        values: A list of floating-point numbers to process.
        limit: An optional threshold; values above this are excluded.

    Returns:
        A new list containing the squared values of the valid inputs.

    Raises:
        ValueError: If the input list is empty.
    """
    if not values:
        raise ValueError("Input values list cannot be empty")

    valid_values = [v for v in values if limit is None or v <= limit]

    return [v ** 2 for v in valid_values]
```

## Reliability

Handle edge cases (empty inputs, invalid types, large datasets) with clear exception handling. Write unit tests for critical paths
and functions, documenting test cases in docstrings.

## Environment and Tooling

Use the existing `uv`-managed virtual environment for all Python code; prompt to create one if missing. CLI scripts must use `uv
run` via a shebang and include a PEP-723 docstring for dependencies.

Preferred defaults: `requests` (HTTP), `click` (CLI), `pydantic` (validation), `pydantic-settings` (secrets), `python-dotenv`,
`pytest` (testing), `pytest-mock` (mocking).

### Script Example

```shell
#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13"
# dependencies = [
#    "requests",
#    "click",
#    "pydantic",
#    "pydantic-settings",
#    "python-dotenv",
# ]
# ///
```
