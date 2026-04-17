#!/usr/bin/env bash
set -euo pipefail

ACCOUNT="${SNOWFLAKE_ACCOUNT:?Set SNOWFLAKE_ACCOUNT}"
PAT="${SNOWFLAKE_PAT:?Set SNOWFLAKE_PAT}"

HOST="https://${ACCOUNT}.snowflakecomputing.com"
MCP_URL="${HOST}/api/v2/databases/AM_SKI_RESORT/schemas/MCP_SERVERS/mcp-servers/ski_resort_mcp"

HEADERS=(
  -H "Authorization: Bearer ${PAT}"
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN"
  -H "Content-Type: application/json"
)

echo "=== Testing MCP Server: ski_resort_mcp ==="
echo "URL: ${MCP_URL}"
echo

echo "--- tools/list ---"
curl -s "${HEADERS[@]}" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  "${MCP_URL}" | python3 -m json.tool
echo

echo "--- tools/call: resort-kpi-summary (GENERIC) ---"
curl -s "${HEADERS[@]}" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"resort-kpi-summary","arguments":{"p_season":"2024-2025"}}}' \
  "${MCP_URL}" | python3 -m json.tool
echo

echo "--- tools/call: daily-summary-analyst (CORTEX_ANALYST_MESSAGE) ---"
curl -s "${HEADERS[@]}" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"daily-summary-analyst","arguments":{"query":"How many total visits in the 2024-2025 season?"}}}' \
  "${MCP_URL}" | python3 -m json.tool
echo

echo "--- tools/call: feedback-search (CORTEX_SEARCH_SERVICE_QUERY) ---"
curl -s "${HEADERS[@]}" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"feedback-search","arguments":{"query":"long lift lines","limit":3}}}' \
  "${MCP_URL}" | python3 -m json.tool
echo

echo "--- tools/call: execute-sql (SYSTEM_EXECUTE_SQL) ---"
curl -s "${HEADERS[@]}" \
  -d '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"execute-sql","arguments":{"query":"SELECT COUNT(*) AS total_feedback FROM AM_SKI_RESORT.MARTS.FACT_FEEDBACK"}}}' \
  "${MCP_URL}" | python3 -m json.tool
echo

echo "=== All tests complete ==="
