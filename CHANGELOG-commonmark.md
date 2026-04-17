

# Changelog

## Unreleased

### Added — Thread Support & Async Transport

- **`build_agent_run_payload()`** — builds the complete JSON payload
  with two modes: local-history (default) and thread mode (`thread_id`
  provided). When both `history` and `thread_id` are given, thread mode
  wins for the upstream payload; local history is for inspection only.
- **`create_thread()`** — sync helper to create a Cortex conversation
  thread. Returns `thread_id` as a string. Raises `KeyError` if the
  response is missing both `thread_id` and `id` fields.
- **`_iter_raw_and_normalized_agent_events()`** — private driver that
  owns the single `seen_tool_result` normalization state machine. All
  higher-level functions (`iter_normalized_agent_events`,
  `collect_agent_events`, `run_agent`) build on this, eliminating
  duplicate normalization loops.
- **`iter_normalized_agent_events()`** — public generator that yields
  normalized `{"event": str, "data": dict}` dicts. Callers do not need
  to track `seen_tool_result` or call `normalize_event()` themselves.
  Recommended for building SSE proxies.
- **Thread params on `stream_agent_sse()`, `collect_agent_events()`,
  `run_agent()`** — all accept optional `thread_id` and
  `parent_message_id`.
- **`AgentResult.thread_metadata`** — `dict[str, Any]` field that
  accumulates metadata events (e.g., `message_id`, `role`).
- **`AgentChat` thread mode** — pass `thread_id` to constructor. Local
  history is always recorded (for transcript/debugging) but not sent
  upstream. Parent message cursor (`_parent_message_id`) advances
  automatically from metadata events. `reset()` clears
  transcript/results/cursor but does NOT unset `thread_id`. `repr` shows
  mode.
- **`normalize_event()` metadata coercion** — `message_id` is always
  coerced to `str` for consistency across numeric/string server
  responses.
- **Async module (`mcp_ski_resort.astream`)** — async equivalents of all
  core streaming functions using `httpx.AsyncClient`. Install with
  `pip install mcp-ski-resort[async]`. All functions accept optional
  `client: httpx.AsyncClient` for connection reuse.
  - `async_create_thread()`, `async_stream_agent_sse()`,
    `async_iter_normalized_agent_events()`,
    `async_collect_agent_events()`, `async_run_agent()`,
    `AsyncAgentChat`.
- Expanded test suite: payload mode tests, metadata coercion, metadata
  merge, AgentChat 2-turn thread-mode synthetic test with parent
  advancement, sync/async signature parity tests.

### Breaking Changes

- **Removed `MCP_URL`** from `mcp_ski_resort.mcp_client`. It was a
  function alias (`MCP_URL = mcp_url`) that looked like a string
  constant but was actually a callable, causing silent bugs in
  f-strings. Use `mcp_url()` instead.
- **Removed module-level `DATABASE` and `AGENT_SCHEMA` constants** from
  `mcp_ski_resort.core`. These are now configurable via
  `SnowflakeSession` fields (`session.database`, `session.agent_schema`)
  and environment variables (`SNOWFLAKE_DATABASE`,
  `SNOWFLAKE_AGENT_SCHEMA`). Defaults are unchanged (`AM_SKI_RESORT` /
  `AGENTS`).

### Added

- **`AgentChat`** — stateful conversation wrapper for Cortex Agents.
  Manages history automatically; inspired by claudette’s `Chat`. Accepts
  `history` param for resume/test and `reset()` returns `self` for
  chaining.
- **`MCPToolbox`** — ergonomic MCP tool wrapper with cached tool list,
  `.describe()`, `.call()`, `.refresh()`, and `tool_names` property.
- **`build_agent_messages()`** — builds the messages payload for the
  Agent `:run` endpoint. Extracted from `stream_agent_sse()` for reuse
  by `AgentChat`.
- **`_finalize_agent_result()`** — post-collection reconciliation that
  promotes thinking→answer for tool-less successful runs where the
  `seen_tool_result` heuristic classified all text as thinking.
- **`_env_or_default()`** — handles empty-string env var override bug
  where `os.environ.get()` returns `""` for `SNOWFLAKE_DATABASE=`.
- **`reset_default_session()`** / **`reset_default_mcp_client()`** —
  clear cached singletons, forcing re-creation on next access.
  Documented caching behavior in `default_session()` and
  `_get_default_client()` docstrings.
- Comprehensive event-semantics tests: 8 scenarios covering thinking
  flush, text accumulation, table parsing, parse errors, tool-less
  answer promotion, tool-using answer flow, error-run guard, and
  `build_agent_messages` payload.

### Improvements

- `parse_agent_response()` now guards `tool_results` access with
  `isinstance()` check to handle unexpected non-dict payloads.
- Both `collect_agent_events()` and `run_agent()` now call
  `_finalize_agent_result()` for consistent end-of-run behavior.
- Demo notebooks (`03_agent_streaming`, `05_mcp_client_demo`) updated to
  showcase `AgentChat` and `MCPToolbox` as the happy-path API.
- Lazy initialization: importing `mcp_ski_resort.core` no longer reads
  environment variables at import time. Use `default_session()` or
  `get_config()` to trigger validation.
- `SnowflakeSession` class replaces module-level auth globals. Now
  carries `database`, `agent_schema`, `mcp_schema`, and
  `mcp_server_name` fields with sensible defaults and env var overrides.
  Supports multiple accounts/sessions and is easier to test.
- `MCPClient` class with `MCPError` exception for JSON-RPC error
  handling.
- `collect_agent_events()` provides a pure, side-effect-free event
  collector.
- `run_agent()` accepts an optional `reporter` callback for custom
  output.
- `stream_agent_sse()` surfaces malformed JSON as `parse_error` events
  instead of silently dropping them.
- `try_parse_json()` strips markdown code fences before parsing.
- `parse_analyst_response()` returns both singular (last-wins) and
  plural list keys.
- `parse_agent_response()` joins text parts with newlines instead of
  concatenating.
- `result_set_to_dataframe()` warns on column count mismatches.
- Dropped deprecated `default_backend()` usage (no-op since cryptography
  3.x).
- HTML escaping in MCP client display helpers.
- `display_mcp_result()` falls back to `_render_json()` for non-dict
  lists instead of routing to `_render_analyst_items()`.
- Trimmed unused imports (`extract_content`, `parse_analyst_response`,
  `parse_search_response`) from `mcp_ski_resort.mcp_client`.
- `run_agent()` docstring documents callback timing (post-apply).
