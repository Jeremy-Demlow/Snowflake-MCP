"""
Test script for Cortex Agent SSE streaming with RSA key-pair JWT auth.

Usage:
    python test_agent_streaming.py

Requires:
    - .env file at project root (see .env.example)
    - RSA private key at the path specified in SNOWFLAKE_PRIVATE_KEY_PATH
    - Key-pair auth configured for your Snowflake user
"""

import base64
import hashlib
import json
import os
import sys
import time
from dataclasses import dataclass, field
from typing import Optional, Generator

import jwt
import requests
import pandas as pd
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from dotenv import load_dotenv

load_dotenv()

SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]
SNOWFLAKE_ROLE = os.environ["SNOWFLAKE_ROLE"]
PRIVATE_KEY_PATH = os.path.expanduser(os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"])

AGENT_DATABASE = "AM_SKI_RESORT"
AGENT_SCHEMA = "AGENTS"

HOST = f"https://{SNOWFLAKE_ACCOUNT}.snowflakecomputing.com"


class JWTGenerator:
    def __init__(self, account: str, user: str, private_key_path: str):
        self.account = account.upper()
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
            digest = hashlib.sha256(pub_bytes).digest()
            self._public_key_fp = "SHA256:" + base64.b64encode(digest).decode()
        return self._private_key

    def get_token(self) -> str:
        now = int(time.time())
        if self._token and now < self._token_exp - 60:
            return self._token

        private_key = self._load_private_key()

        account_id = self.account.replace(".snowflakecomputing.com", "").replace("-", "_")
        qualified = f"{account_id}.{self.user}"

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


def get_headers(accept: str = "text/event-stream") -> dict:
    return {
        "Authorization": f"Bearer {jwt_gen.get_token()}",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT",
        "X-Snowflake-Role": SNOWFLAKE_ROLE,
        "Content-Type": "application/json",
        "Accept": accept,
    }


def stream_agent_sse(
    agent_name: str,
    question: str,
    history: list[dict] | None = None,
) -> Generator[dict, None, None]:
    endpoint = (
        f"{HOST}/api/v2/databases/{AGENT_DATABASE}"
        f"/schemas/{AGENT_SCHEMA}/agents/{agent_name}:run"
    )

    messages = []
    for m in (history or []):
        messages.append({
            "role": m["role"],
            "content": [{"type": "text", "text": m["content"]}],
        })
    messages.append({
        "role": "user",
        "content": [{"type": "text", "text": question}],
    })

    payload = {"messages": messages}

    print(f"  POST {endpoint}")
    with requests.post(endpoint, headers=get_headers(), json=payload, stream=True, timeout=120) as resp:
        if not resp.ok:
            print(f"  ERROR {resp.status_code}: {resp.text[:500]}")
            resp.raise_for_status()

        current_event: Optional[str] = None
        data_buffer: list[str] = []

        for raw_line in resp.iter_lines(decode_unicode=True):
            if raw_line is None:
                continue

            if not raw_line:
                if data_buffer and current_event is not None:
                    joined = "\n".join(data_buffer)
                    if joined == "[DONE]":
                        yield {"event": "done", "data": {}}
                        return
                    try:
                        data = json.loads(joined)
                        yield {"event": current_event, "data": data}
                    except json.JSONDecodeError:
                        print(f"  WARN: unparseable data for {current_event}: {joined[:100]}")
                current_event = None
                data_buffer = []
                continue

            if raw_line.startswith("event:"):
                current_event = raw_line[6:].strip()
                continue

            if raw_line.startswith("data:"):
                data_buffer.append(raw_line[5:].strip())
                continue

        if data_buffer and current_event is not None:
            joined = "\n".join(data_buffer)
            if joined == "[DONE]":
                yield {"event": "done", "data": {}}
                return
            try:
                data = json.loads(joined)
                yield {"event": current_event, "data": data}
            except json.JSONDecodeError:
                pass


def normalize_event(raw_event: str, data: dict, seen_tool_result: bool = False) -> list[dict]:
    results = []

    if raw_event == "response.text.delta":
        text = data.get("text")
        if text:
            evt = "text" if seen_tool_result else "thinking"
            results.append({"event": evt, "data": {"text": text}})

    elif raw_event == "response.thinking.delta":
        text = data.get("thinking") or data.get("text", "")
        if text:
            results.append({"event": "thinking", "data": {"text": text}})

    elif raw_event == "response.thinking":
        text = data.get("thinking") or data.get("text", "")
        if text:
            results.append({"event": "thinking_complete", "data": {"text": text}})

    elif raw_event == "response.status":
        msg = data.get("status_message") or data.get("message", "")
        if msg:
            results.append({"event": "status", "data": {"message": msg}})

    elif raw_event == "response.tool_use":
        name = data.get("name", "")
        clean = name.replace("cortex_analyst_text_to_sql__", "").replace("_", " ")
        if clean:
            results.append({"event": "tool", "data": {"name": clean}})

    elif raw_event == "response.tool_result":
        for item in data.get("content", []):
            j = item.get("json", {}) if isinstance(item, dict) else {}
            if j.get("sql"):
                results.append({"event": "sql", "data": {"sql": j["sql"]}})
            if j.get("result_set"):
                results.append({"event": "table", "data": j["result_set"]})

    elif raw_event == "response.chart":
        raw_spec = data.get("chart_spec")
        if raw_spec:
            try:
                spec = json.loads(raw_spec) if isinstance(raw_spec, str) else raw_spec
                results.append({"event": "chart", "data": spec})
            except json.JSONDecodeError:
                pass

    elif raw_event == "response.text.annotation":
        results.append({"event": "annotation", "data": data})

    elif raw_event == "response.error":
        msg = data.get("message") or data.get("error", "An error occurred")
        results.append({"event": "error", "data": {"message": msg}})

    elif raw_event == "metadata":
        results.append({"event": "metadata", "data": data.get("metadata", data)})

    elif raw_event == "done":
        results.append({"event": "done", "data": {}})

    return results


@dataclass
class AgentResult:
    answer: str = ""
    thinking: list[str] = field(default_factory=list)
    sql_queries: list[str] = field(default_factory=list)
    result_sets: list[dict] = field(default_factory=list)
    dataframes: list[pd.DataFrame] = field(default_factory=list)
    chart_specs: list[dict] = field(default_factory=list)
    tools_used: list[str] = field(default_factory=list)
    statuses: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    raw_events: list[dict] = field(default_factory=list)
    duration_seconds: float = 0.0


def result_set_to_dataframe(rs: dict) -> pd.DataFrame:
    data = rs.get("data", [])
    if not data:
        return pd.DataFrame()
    row_type = rs.get("resultSetMetaData", {}).get("rowType", [])
    if row_type:
        col_names = [r.get("name", f"col_{i}") for i, r in enumerate(row_type)]
        return pd.DataFrame(data, columns=col_names)
    columns = rs.get("columns", [])
    col_names = [c if isinstance(c, str) else c.get("name", f"col_{i}") for i, c in enumerate(columns)]
    if col_names:
        return pd.DataFrame(data, columns=col_names)
    if isinstance(data[0], dict):
        return pd.DataFrame(data)
    return pd.DataFrame(data)


def run_agent(agent_name: str, question: str, history=None) -> AgentResult:
    result = AgentResult()
    start = time.time()
    seen_tool_result = False
    current_thinking = ""

    for raw in stream_agent_sse(agent_name, question, history):
        result.raw_events.append(raw)
        raw_event = raw["event"]
        raw_data = raw.get("data", {})

        if raw_event == "response.tool_result":
            seen_tool_result = True

        normalized = normalize_event(raw_event, raw_data, seen_tool_result=seen_tool_result)

        for evt in normalized:
            etype = evt["event"]
            edata = evt["data"]

            if etype == "text":
                result.answer += edata.get("text", "")
            elif etype == "thinking":
                current_thinking += edata.get("text", "")
            elif etype == "thinking_complete":
                if current_thinking:
                    result.thinking.append(current_thinking)
                    current_thinking = ""
                if edata.get("text"):
                    result.thinking.append(edata["text"])
            elif etype == "status":
                result.statuses.append(edata.get("message", ""))
                print(f"  [status] {edata.get('message', '')}")
            elif etype == "tool":
                name = edata.get("name", "")
                if name not in result.tools_used:
                    result.tools_used.append(name)
                print(f"  [tool] {name}")
            elif etype == "sql":
                result.sql_queries.append(edata.get("sql", ""))
                print(f"  [sql] {edata.get('sql', '')[:80]}...")
            elif etype == "table":
                result.result_sets.append(edata)
                df = result_set_to_dataframe(edata)
                result.dataframes.append(df)
                print(f"  [table] {len(df)} rows x {len(df.columns)} cols")
            elif etype == "chart":
                result.chart_specs.append(edata)
                print(f"  [chart] Vega-Lite spec received")
            elif etype == "error":
                result.errors.append(edata.get("message", ""))
                print(f"  [ERROR] {edata.get('message', '')}")

    if current_thinking:
        result.thinking.append(current_thinking)

    result.duration_seconds = round(time.time() - start, 2)
    return result


def cortex_search(service_name: str, query: str, columns: list[str], max_results: int = 10, filter_obj: dict | None = None) -> pd.DataFrame:
    endpoint = (
        f"{HOST}/api/v2/databases/{AGENT_DATABASE}"
        f"/schemas/{AGENT_SCHEMA}/cortex-search-services/{service_name}:query"
    )
    payload = {"query": query, "columns": columns, "limit": max_results}
    if filter_obj:
        payload["filter"] = filter_obj

    print(f"  POST {endpoint}")
    resp = requests.post(endpoint, headers=get_headers(accept="application/json"), json=payload, timeout=30)
    if not resp.ok:
        print(f"  ERROR {resp.status_code}: {resp.text[:500]}")
        resp.raise_for_status()

    results = resp.json().get("results", [])
    return pd.DataFrame(results) if results else pd.DataFrame()


def print_result(result: AgentResult, label: str = ""):
    print(f"\n{'=' * 60}")
    if label:
        print(f"  {label}")
    print(f"  Duration: {result.duration_seconds}s")
    print(f"  Tools: {result.tools_used}")
    print(f"  SQL queries: {len(result.sql_queries)}")
    print(f"  Result sets: {len(result.dataframes)}")
    print(f"  Charts: {len(result.chart_specs)}")
    print(f"  Thinking steps: {len(result.thinking)}")
    print(f"  Errors: {result.errors}")
    print(f"  Raw events: {len(result.raw_events)}")

    if result.answer:
        print(f"\n  --- Answer (first 500 chars) ---")
        print(f"  {result.answer[:500]}")

    for i, df in enumerate(result.dataframes):
        print(f"\n  --- DataFrame {i+1} ({len(df)} rows) ---")
        print(df.head(5).to_string(index=False))

    print(f"{'=' * 60}\n")


def test_jwt_generation():
    print("TEST 1: JWT Token Generation")
    print(f"  Account: {SNOWFLAKE_ACCOUNT}")
    print(f"  User: {SNOWFLAKE_USER}")
    print(f"  Key: {PRIVATE_KEY_PATH}")
    try:
        token = jwt_gen.get_token()
        print(f"  Token: {token[:50]}...{token[-20:]}")
        print(f"  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        return False


def test_agent_streaming():
    print("TEST 2: Agent SSE Streaming (RESORT_EXECUTIVE)")
    print(f"  Question: 'How many total visits in the 2024-2025 season?'")
    try:
        result = run_agent(
            "RESORT_EXECUTIVE",
            "How many total visits in the 2024-2025 season?"
        )
        print_result(result, "RESORT_EXECUTIVE Response")

        assert len(result.raw_events) > 0, "No events received"
        assert result.answer, "No answer text"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback
        traceback.print_exc()
        return False


def test_ops_agent():
    print("TEST 3: Agent SSE Streaming (SKI_OPS_ASSISTANT)")
    print(f"  Question: 'What are the top 5 lifts by average wait time this season?'")
    try:
        result = run_agent(
            "SKI_OPS_ASSISTANT",
            "What are the top 5 lifts by average wait time for the 2024-2025 season?"
        )
        print_result(result, "SKI_OPS_ASSISTANT Response")

        assert len(result.raw_events) > 0, "No events received"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback
        traceback.print_exc()
        return False


def test_cortex_search():
    print("TEST 4: Cortex Search (feedback_search)")
    try:
        df = cortex_search(
            "feedback_search",
            "long lift lines and wait times",
            ["feedback_text", "rating", "sentiment", "category"],
            max_results=5,
        )
        print(f"  Results: {len(df)} rows")
        if len(df) > 0:
            print(df[["feedback_text", "rating", "sentiment"]].head(3).to_string(index=False))
        assert len(df) > 0, "No search results"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback
        traceback.print_exc()
        return False


def test_incident_search():
    print("TEST 5: Cortex Search (incident_search)")
    try:
        df = cortex_search(
            "incident_search",
            "collision on black diamond trail",
            ["description", "severity", "trail_name", "cause"],
            max_results=5,
        )
        print(f"  Results: {len(df)} rows")
        if len(df) > 0:
            print(df[["description", "severity", "trail_name"]].head(3).to_string(index=False))
        assert len(df) > 0, "No search results"
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback
        traceback.print_exc()
        return False


def test_raw_events():
    print("TEST 6: Raw Event Inspector")
    print(f"  Dumping raw SSE events from RESORT_EXECUTIVE...")
    try:
        count = 0
        for raw in stream_agent_sse("RESORT_EXECUTIVE", "How many total visits last season?"):
            evt = raw["event"]
            data_preview = json.dumps(raw.get("data", {}))[:150]
            print(f"  [{count:03d}] event={evt:<30s} data={data_preview}")
            count += 1
            if evt == "done":
                break
        assert count > 0, "No events"
        print(f"  Total events: {count}")
        print("  PASS\n")
        return True
    except Exception as e:
        print(f"  FAIL: {e}\n")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("  Cortex Agent Streaming Test Suite")
    print(f"  Host: {HOST}")
    print(f"  Database: {AGENT_DATABASE}.{AGENT_SCHEMA}")
    print("=" * 60)
    print()

    tests = [
        ("JWT Generation", test_jwt_generation),
        ("Agent Streaming (Executive)", test_agent_streaming),
        ("Agent Streaming (Ops)", test_ops_agent),
        ("Cortex Search (Feedback)", test_cortex_search),
        ("Cortex Search (Incidents)", test_incident_search),
        ("Raw Event Inspector", test_raw_events),
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
