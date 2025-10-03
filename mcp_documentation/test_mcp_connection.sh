#!/bin/bash

# ============================================================================
# TEST MCP CONNECTION
# Usage: ./test_mcp_connection.sh YOUR-PAT-TOKEN
# ============================================================================

if [ -z "$1" ]; then
    echo "❌ Error: PAT token required"
    echo "Usage: ./test_mcp_connection.sh YOUR-PAT-TOKEN"
    exit 1
fi

PAT_TOKEN="$1"
MCP_URL="https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/SNOWFLAKE_DOCS"

echo "🧪 Testing MCP connection..."
echo "📍 URL: $MCP_URL"
echo ""

# Test tools/list endpoint
RESPONSE=$(curl -s -X POST "$MCP_URL" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer $PAT_TOKEN" \
  --data '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }')

# Check if request was successful
if echo "$RESPONSE" | grep -q '"result"'; then
    echo "✅ SUCCESS! MCP server is responding"
    echo ""
    echo "📋 Available tools:"
    echo "$RESPONSE" | python3 -m json.tool
    echo ""
    echo "🎉 You're ready to configure Cursor!"
    echo "👉 Next: Update mcp.json with your PAT token and add to Cursor settings"
else
    echo "❌ FAILED - Error response:"
    echo "$RESPONSE" | python3 -m json.tool
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  1. Verify PAT token is correct and not expired"
    echo "  2. Check that SNOWFLAKE_DOCS_ROLE has proper permissions"
    echo "  3. Ensure MCP server exists: SHOW MCP SERVERS;"
fi

