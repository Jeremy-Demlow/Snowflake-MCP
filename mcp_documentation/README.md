# Snowflake Documentation MCP Server for Cursor

This setup exposes Snowflake's official documentation to Cursor via an MCP server, enabling accurate code generation with proper Snowflake syntax.

## 🎯 What This Does

Connects Cursor to Snowflake's documentation so it can:
- ✅ Generate correct SQL syntax
- ✅ Use proper function signatures
- ✅ Follow Snowflake best practices
- ✅ Validate commands and arguments

## 🚀 Quick Setup (5 minutes)

### Prerequisites
1. Snowflake account
2. User with ACCOUNTADMIN role or permissions granted to you
3. Snowflake Documentation Cortex Knowledge Extension installed
4. Cursor IDE

### Step 1: Create MCP Server ✅ DONE

The MCP server is already created! Here's what we set up:
- **Database**: `MCP`
- **Schema**: `MCP_SERVERS`
- **MCP Server**: `SNOWFLAKE_DOCS`
- **Role**: `SNOWFLAKE_DOCS_ROLE`

### Step 2: Generate PAT Token

You need to generate a PAT token using Snowsight UI (cannot use PAT to create PAT):

1. **Go to Snowsight**: https://app.snowflake.com/
2. **Navigate to**: Admin → Users & Roles → Users
3. **Find user**: `<USER_NAME>`
4. **Click** the user, then go to "Programmatic Access Tokens"
5. **Click "Add Token"** and use these settings:
   ```
   Token Name: cursor_docs_token
   Role Restriction: SNOWFLAKE_DOCS_ROLE
   Days to Expiry: 90
   ```
6. **Copy the token immediately** - you can't retrieve it again!

**Alternative: Use SQL in Snowsight (not CLI):**
```sql
ALTER USER <USER_NAME> 
ADD PROGRAMMATIC ACCESS TOKEN cursor_docs_token
    ROLE_RESTRICTION = 'SNOWFLAKE_DOCS_ROLE'
    DAYS_TO_EXPIRY = 90;
```

### Step 3: Configure Cursor

1. **Open Cursor Settings**: `⌘,` (Cmd+Comma)
2. **Navigate to**: Cursor Settings → Tools & MCP
3. **Click**: "Add Custom MCP"
4. **Edit mcp.json** with:

```json
{
  "mcpServers": {
    "snowflake-docs": {
      "url": "https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/SNOWFLAKE_DOCS",
      "headers": {
        "Authorization": "Bearer <PASTE-YOUR-PAT-TOKEN-HERE>"
      }
    }
  }
}
```

5. **Save** the file
6. **Hover** over "snowflake-docs" in the MCP tools list
7. **Click** to enable the tool

### Step 4: Test Connection

Test with curl:
```bash
curl -X POST "https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/SNOWFLAKE_DOCS" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer YOUR-PAT-TOKEN" \
  --data '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }'
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "snowflake-docs",
        "description": "Search Snowflake documentation...",
        "type": "CORTEX_SEARCH_SERVICE_QUERY"
      }
    ]
  }
}
```

### Step 5: Test in Cursor

Try this prompt in Cursor:
```
Create a Snowflake stored procedure that generates a date dimension table
```

Cursor should:
- Use the `snowflake-docs` tool to look up proper syntax
- Generate correct Snowflake Scripting code
- Use proper function signatures (DATEADD, GENERATOR, etc.)

## 📁 Files

| File | Purpose |
|------|---------|
| `setup_snowflake_docs_mcp.sql` | Creates MCP server and permissions |
| `mcp.json.example` | Cursor configuration template |
| `context_snowflake_mcp.txt` | Full documentation and context |

## 🔐 Security

- **Role Restriction**: PAT is limited to `SNOWFLAKE_DOCS_ROLE` (read-only)
- **Limited Scope**: Only has access to documentation search, nothing else
- **90-day Expiry**: Token expires automatically

## 🧪 Testing Queries

Once configured, test with these prompts:

1. **Date Functions**:
   ```
   Show me how to use DATEADD with proper syntax
   ```

2. **Stored Procedures**:
   ```
   Create a stored procedure with EXECUTE IMMEDIATE
   ```

3. **Window Functions**:
   ```
   Write a query using ROW_NUMBER with PARTITION BY
   ```

## 🔧 Troubleshooting

### Issue: "Loading tools..." never completes

**Solution**: Test connection with curl to verify token and URL

### Issue: Token expired

**Solution**: Generate new token in Snowsight:
```sql
ALTER USER <USER_NAME> 
ADD PROGRAMMATIC ACCESS TOKEN cursor_docs_token_2
    ROLE_RESTRICTION = 'SNOWFLAKE_DOCS_ROLE'
    DAYS_TO_EXPIRY = 90;
```

### Issue: Permission denied

**Solution**: Verify role grants:
```sql
SHOW GRANTS TO ROLE SNOWFLAKE_DOCS_ROLE;
```

## 📊 What's Different?

**Before MCP**:
- ❌ Incorrect syntax (missing colons on bind variables)
- ❌ Wrong function arguments
- ❌ Made-up commands
- ⚠️ Required manual corrections

**After MCP**:
- ✅ Correct syntax on first try
- ✅ Proper function signatures
- ✅ Real Snowflake commands
- ✅ Works immediately

## 🎓 Next Steps

1. Generate your PAT token (Step 2)
2. Configure Cursor (Step 3)
3. Test the connection (Step 4)
4. Start coding with better accuracy! (Step 5)

---

**Account**: `<ACCOUNT_NAME>.snowflakecomputing.com`  
**MCP Server URL**: `https://<ACCOUNT_NAME>.snowflakecomputing.com/api/v2/databases/MCP/schemas/MCP_SERVERS/mcp-servers/SNOWFLAKE_DOCS`
