# Contributing

This project uses [nbdev](https://nbdev.fast.ai/) for notebook-driven development. **Notebooks are the single source of truth** — never edit `.py` files directly.

---

## Development Setup

```bash
git clone <repo-url>
cd Snowflake-MCP
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env
# Edit .env with your Snowflake credentials
pre-commit install
```

---

## Pre-commit Hooks

After `pre-commit install`, every `git commit` automatically runs:

- **detect-private-key** — blocks commits containing RSA/DSA/EC private keys
- **detect-secrets** — catches high-entropy strings (tokens, keys, account locators)
- **check-added-large-files** — prevents files > 500KB
- **trailing-whitespace** / **end-of-file-fixer** — formatting cleanup

To run hooks manually:

```bash
pre-commit run --all-files
```

---

## nbdev Workflow

### Edit notebooks, not .py files

All library code lives in `00_core.ipynb`, `01_async.ipynb`, and `02_mcp_client.ipynb`. After editing:

```bash
nbdev-export     # Regenerate mcp_ski_resort/*.py from notebooks
nbdev-test       # Run all notebook cells (except #| eval: false)
nbdev-prepare    # Export + test + clean — run before every commit
```

### Key nbdev directives

| Directive | Purpose |
|---|---|
| `#\| default_exp module_name` | Sets which module this notebook exports to |
| `#\| export` | Marks a cell for export to the .py module |
| `#\| hide` | Hides cell from documentation |
| `#\| eval: false` | Skips cell during `nbdev-test` (use for live API calls) |

---

## Adding a New Library Module

1. Create `NN_name.ipynb` (e.g., `06_analytics.ipynb`)
2. First cell: `#| default_exp name`
3. Add `#| export` to cells that should become library code
4. Last cell: `#| hide` with `from nbdev import nbdev_export; nbdev_export()`
5. Run `nbdev-export` to generate `mcp_ski_resort/name.py`

---

## Adding a New Demo Notebook

1. Create `NN_name.ipynb` (e.g., `06_dashboard_demo.ipynb`)
2. **Do not** include `#| default_exp` — demo notebooks don't export code
3. Import from the library: `from mcp_ski_resort.core import ...`
4. Mark all live API cells with `#| eval: false` so `nbdev-test` doesn't need credentials

---

## Testing

```bash
# Notebook tests (no credentials needed — eval:false cells are skipped)
nbdev-test

# Live integration tests (requires .env with valid credentials)
python tests/test_agent_streaming.py
python tests/test_mcp_client.py
```

---

## PR Process

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Edit notebooks (not .py files)
3. Run `nbdev-prepare` (exports, tests, cleans notebooks)
4. Commit and push
5. Open a PR with a description of what changed and why
