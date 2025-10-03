#!/bin/bash

# ============================================================================
# TEST FINANCIAL SERVICES MCP CONNECTION
# Usage: ./test_financial_mcp.sh YOUR-PAT-TOKEN
# ============================================================================

if [ -z "$1" ]; then
    echo "❌ Error: PAT token required"
    echo "Usage: ./test_financial_mcp.sh YOUR-PAT-TOKEN"
    exit 1
fi

PAT_TOKEN="$1"
MCP_URL="https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/financial_services_mcp"

echo "🧪 Testing Financial Services MCP connection..."
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
    echo "✅ SUCCESS! Financial Services MCP server is responding"
    echo ""
    echo "📋 Available tools:"
    echo "$RESPONSE" | python3 -m json.tool
    echo ""
    echo "🎉 You're ready to add this to Cursor!"
    echo "👉 Next: Update Cursor's mcp.json with this server"
else
    echo "❌ FAILED - Error response:"
    echo "$RESPONSE" | python3 -m json.tool
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  1. Verify PAT token is correct and not expired"
    echo "  2. Check that mcp_user_role has proper permissions"
    echo "  3. Ensure MCP server exists: SHOW MCP SERVERS;"
fi

