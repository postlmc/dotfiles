---
description: 'Guidelines to write comments to produce more descriptive code.'
applyTo: '**/*.c, **/*.cpp, **/*.go, **/*.java, **/*.js, **/*.py, **/*.rs, **/*.ts'
---

# Self-explanatory Code Commenting Instructions

## Core Principle

**Write code that speaks for itself. Comment only when necessary to explain WHY, not WHAT.** If this is done correctly, comments are
not needed most of the time. **Do not use emoji in code, comments, or documentation.**

## Commenting Guidelines

### AVOID These Comment Types

**Obvious Comments**
```python
# Bad: States the obvious
counter = 0  # Initialize counter to zero
counter += 1  # Increment counter by one
```

**Redundant Comments**
```python
# Bad: Comment repeats the code
def get_user_name():
    return user.name  # Return the user's name
```

**Outdated Comments**
```python
# Bad: Comment doesn't match the code
# Calculate tax at 5% rate
tax = price * 0.08  # Actually 8%
```

### WRITE These Comment Types

**Complex Business Logic**
```python
# Good: Explains WHY this specific calculation
# Apply progressive tax brackets: 10% up to 10k, 20% above
tax = calculate_progressive_tax(income, [0.10, 0.20], [10000])
```

**Non-obvious Algorithms**
```python
# Good: Explains the algorithm steps and reasoning
# Exponential backoff: base * 2^(attempt - 1)
delay = min(base_delay * (2 ** (attempt - 1)), max_delay)

# Add randomness (jitter) to prevent thundering herd problem
return delay + random.uniform(0, 1.0)
```

**Regex Patterns**
```python
# Good: Explains what the regex matches
# Match email format: username@domain.extension
email_pattern = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
```

**API Constraints or Gotchas**
```python
# Good: Explains external constraint
# GitHub API rate limit: 5000 requests/hour for authenticated users
await rate_limiter.wait()
response = await http_client.get(github_api_url)
```

## Decision Framework

Before writing a comment, ask:
1. **Is the code self-explanatory?** → No comment needed
2. **Would a better variable/function name eliminate the need?** → Refactor instead
3. **Does this explain WHY, not WHAT?** → Good comment
4. **Will this help future maintainers?** → Good comment

## Special Cases for Comments

### Public APIs

Public functions and methods require docstrings documenting parameters, return values, and exceptions. See language-specific
instruction files for format examples.

### Configuration and Constants
```python
# Good: Explains the source or reasoning
MAX_RETRIES = 3  # Based on network reliability studies
API_TIMEOUT = 5000  # AWS Lambda timeout is 15s, leaving buffer
```

### Annotations
```python
# TODO: Replace with proper user authentication after security review
# FIXME: Memory leak in production - investigate connection pooling
# HACK: Workaround for bug in library v2.1.0 - remove after upgrade
# NOTE: This implementation assumes UTC timezone for all calculations
# WARNING: This function modifies the original array instead of creating a copy
# PERF: Consider caching this result if called frequently in hot path
# SECURITY: Validate input to prevent SQL injection before using in query
# BUG: Edge case failure when array is empty - needs investigation
# REFACTOR: Extract this logic into separate utility function for reusability
# DEPRECATED: Use new_api_function() instead - this will be removed in v3.0
```

## Anti-Patterns to Avoid

### Dead Code Comments
```python
# Bad: Don't comment out code
# def old_function(): ...
def new_function(): ...
```

### Changelog Comments
```python
# Bad: Don't maintain history in comments
# Modified by John on 2023-01-15
# Fixed bug reported by Sarah on 2023-02-03
def process_data():
    # ... implementation
```

### Divider Comments
```python
# Bad: Don't use decorative comments
#=====================================
# UTILITY FUNCTIONS
#=====================================
```

## Quality Checklist

Before committing, ensure your comments:
- [ ] Explain WHY, not WHAT
- [ ] Are grammatically correct and clear
- [ ] Will remain accurate as code evolves
- [ ] Add genuine value to code understanding
- [ ] Are placed appropriately (above the code they describe)
- [ ] Use proper spelling and professional language
