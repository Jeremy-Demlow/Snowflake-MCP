"""
Test MCP Server JSON-RPC client with RSA key-pair JWT auth.

Tests all 5 tool types via the Snowflake-managed MCP server:
  1. tools/list                  — discover available tools
  2. CORTEX_ANALYST_MESSAGE      — natural language to SQL
  3. CORTEX_AGENT_RUN            — agent streaming via MCP
  4. CORTEX_SEARCH_SERVICE_QUERY — semantic search
  5. SYSTEM_EXECUTE_SQL           — ad-hoc SQL
  6. GENERIC (UDF)               — custom UDF tool

Usage:
    python test_mcp_client.py        # run all
    python test_mcp_client.py 2      # run single test
"""

import base64
import hashlib
import json
import os
import sys
import time
from typing import Optional

import jwt
import requests
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from dotenv import load_dotenv

load_dotenv()

SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]
SNOWFLAKE_ROLE = os.environ["SNOWFLAKE_ROLE"]
PRIVATE_KEY_PATH = os.path.expanduser(os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"])

HOST = f"https://{SNOWFLAKE_ACCOUNT}.snowflakecomputing.com"
MCP_URL = f"{HOST}/api/v2/databases/AM_SKI_RESORT/schemas/MCP_SERVERS/mcp-servers/ski_resort_mcp"


class JWTGenerator:
    def __init__(self, account: str, user: str, private_key_path: str):
        self.account = account.upper().replace("-", "_")
        self.user = user.upper()
        self.private_key_path = private_key_path
        self._private_key = None
        self._public_key_fp: Optional[str] = None
        self._token: Optional[str] = None
        self._token_exp: int = 0

    def _load_private_key(self):
        if self._private_key is None:
            with open(self.private_key_path, "rb") as f:
                self._private_key = serialization.load_pem_private_key(
                    f.read(), password=None, backend=default_backend()
                )
            pub_bytes = self._private_key.public_key().public_bytes(
                serialization.Encoding.DER,
                serialization.PublicFormat.SubjectPublicKeyInfo,
            )
            self._public_key_fp = "SHA256:" + base64.b64encode(
                hashlib.sha256(pub_bytes).digest()
            ).decode()
        return self._private_key

    def get_token(self) -> str:
        now = int(time.time())
        if self._token and now < self._token_exp - 60:
            return self._token
        private_key = self._load_private_key()
        qualified = f"{self.account}.{self.user}"
        exp = now + 3600
        payload = {
            "iss": f"{qualified}.{self._public_key_fp}",
            "sub": qualified,
            "iat": now,
            "exp": exp,
        }
        self._token = jwt.encode(payload, private_key, algorithm="RS256")
        self._token_exp = exp
        return self._token


jwt_gen = JWTGenerator(SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, PRIVATE_KEY_PATH)


def get_headers() -> dict:
    return {
        "Authorization": f"Bearer {jwt_gen.get_token()}",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT",
        "X-Snowflake-Role": SNOWFLAKE_ROLE,
        "Content-Type": "application/json",
    }


def mcp_request(method: str, params: dict | None = None, req_id: int = 1) -> dict:
    body = {
        "jsonrpc": "2.0",
        "id": req_id,
        "method": method,
    }
    if params:
        body["params"] = params

    resp = requests.post(MCP_URL, headers=get_headers(), json=body, timeout=120)
    if not resp.ok:
        print(f"  HTTP {resp.status_code}: {resp.text[:500]}")
        resp.raise_for_status()
    return resp.json()


def mcp_tools_list() -> list[dict]:
    result = mcp_request("tools/list")
    return result.get("result", {}).get("tools", [])


def mcp_tools_call(tool_name: str, arguments: dict, req_id: int = 1) -> dict:
    return mcp_request("tools/call", {"name": tool_name, "arguments": arguments}, req_id)


def test_tools_list():
    print("TEST 1: tools/list — Discover MCP tools")
    print(f"  URL: {MCP_URL}")
    try:
        tools = mcp_tools_list()
        print(f"  Found {len(tools)} tools:")
        for t in tools:
            print(f"    - {t['name']}: {t.get('description', '')[:80]}")
        assert len(tools) > 0, "No tools returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_analyst_tool():
    print("TEST 2: tools/call — CORTEX_ANALYST_MESSAGE (daily-summary-analyst)")
    try:
        result = mcp_tools_call("daily-summary-analyst", {
            "message": "How many total visits in the 2024-2025 season?"
        }, req_id=2)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content:
            text = item.get("text", "")
            print(f"    [{item.get('type')}] {text[:200]}")
        assert len(content) > 0, "No content returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_agent_tool():
    print("TEST 3: tools/call — CORTEX_AGENT_RUN (resort-executive-agent)")
    try:
        result = mcp_tools_call("resort-executive-agent", {
            "text": "What was total revenue for the 2024-2025 season?"
        }, req_id=3)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content[:5]:
            text = item.get("text", "")
            print(f"    [{item.get('type')}] {text[:200]}")
        assert len(content) > 0, "No content returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_search_tool():
    print("TEST 4: tools/call — CORTEX_SEARCH_SERVICE_QUERY (feedback-search)")
    try:
        result = mcp_tools_call("feedback-search", {
            "query": "long lift lines and crowded slopes",
            "columns": ["feedback_text", "rating", "sentiment", "category"],
            "limit": 5,
        }, req_id=4)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content[:3]:
            text = item.get("text", "")
            print(f"    [{item.get('type')}] {text[:200]}")

        results_data = result.get("result", {}).get("results", {})
        if results_data:
            print(f"    Results object keys: {list(results_data.keys())}")

        assert content or results_data, "No content or results returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_sql_tool():
    print("TEST 5: tools/call — SYSTEM_EXECUTE_SQL (execute-sql)")
    try:
        result = mcp_tools_call("execute-sql", {
            "sql": "SELECT COUNT(*) AS total_rows FROM AM_SKI_RESORT.MARTS.FACT_TICKET_SALES"
        }, req_id=5)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content:
            text = item.get("text", "")
            print(f"    [{item.get('type')}] {text[:300]}")
        assert len(content) > 0, "No content returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_generic_udf():
    print("TEST 6: tools/call — GENERIC UDF (resort-kpi-summary)")
    try:
        result = mcp_tools_call("resort-kpi-summary", {
            "p_season": "2024-2025"
        }, req_id=6)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content:
            text = item.get("text", "")
            if text:
                try:
                    parsed = json.loads(text)
                    print(f"    [{item.get('type')}] JSON keys: {list(parsed.keys()) if isinstance(parsed, dict) else 'array'}")
                    print(f"    Preview: {json.dumps(parsed, indent=2)[:400]}")
                except json.JSONDecodeError:
                    print(f"    [{item.get('type')}] {text[:300]}")
        assert len(content) > 0, "No content returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


def test_weather_udf():
    print("TEST 7: tools/call — GENERIC UDF (weather-impact-report)")
    try:
        result = mcp_tools_call("weather-impact-report", {
            "p_start_date": "2025-01-01",
            "p_end_date": "2025-03-31",
        }, req_id=7)
        content = result.get("result", {}).get("content", [])
        print(f"  Content items: {len(content)}")
        for item in content:
            text = item.get("text", "")
            if text:
                try:
                    parsed = json.loads(text)
                    print(f"    [{item.get('type')}] JSON keys: {list(parsed.keys()) if isinstance(parsed, dict) else 'array'}")
                except json.JSONDecodeError:
                    print(f"    [{item.get('type')}] {text[:300]}")
        assert len(content) > 0, "No content returned"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback; traceback.print_exc()
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("  MCP Server Client Test Suite")
    print(f"  MCP URL: {MCP_URL}")
    print("=" * 60)
    print()

    tests = [
        ("tools/list", test_tools_list),
        ("Analyst Tool", test_analyst_tool),
        ("Agent Tool", test_agent_tool),
        ("Search Tool", test_search_tool),
        ("SQL Tool", test_sql_tool),
        ("Generic UDF (KPI)", test_generic_udf),
        ("Generic UDF (Weather)", test_weather_udf),
    ]

    if len(sys.argv) > 1:
        test_num = int(sys.argv[1])
        if 1 <= test_num <= len(tests):
            name, fn = tests[test_num - 1]
            print(f"Running single test: {name}\n")
            fn()
            sys.exit(0)

    results = {}
    for name, fn in tests:
        results[name] = fn()

    print("\n" + "=" * 60)
    print("  SUMMARY")
    print("=" * 60)
    for name, passed in results.items():
        status = "PASS" if passed else "FAIL"
        print(f"  [{status}] {name}")

    total = len(results)
    passed = sum(1 for v in results.values() if v)
    print(f"\n  {passed}/{total} tests passed")
    sys.exit(0 if all(results.values()) else 1)
