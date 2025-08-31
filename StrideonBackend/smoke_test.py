#!/usr/bin/env python3
"""
StrideOn Backend — Automated Smoke Test

Quickly verifies that the backend is up and essential endpoints respond.
Optionally exercises JWT-protected endpoints when a SUPABASE JWT is provided.

Usage:
  python3 smoke_test.py --host http://127.0.0.1:8000 [--jwt <TOKEN>]

Exit codes:
  0 = all selected checks passed
  1 = one or more checks failed
"""
from __future__ import annotations
import argparse
import os
import sys
from typing import List, Tuple

# Try to use httpx if available; otherwise fall back to urllib
try:
    import httpx  # type: ignore
except Exception:  # pragma: no cover
    httpx = None  # type: ignore
import json
import urllib.request
import urllib.error


def _request_with_urllib(method: str, url: str, headers: dict | None = None, timeout: float = 5.0) -> Tuple[int, str]:
    req = urllib.request.Request(url=url, method=method)
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:  # nosec - local smoke test
            status = resp.getcode() or 0
            body = resp.read().decode("utf-8", errors="replace")
            return status, body
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace") if hasattr(e, 'read') else str(e)
        return e.code, body
    except Exception as e:
        return 0, f"EXC {e}"


def check_with_httpx(client: 'httpx.Client', method: str, url: str, **kwargs) -> Tuple[bool, str]:
    try:
        resp = client.request(method, url, timeout=5.0, **kwargs)
        ok = 200 <= resp.status_code < 300
        msg = f"{resp.status_code} {resp.text[:200]}"
        return ok, msg
    except Exception as e:
        return False, f"EXC {e}"


def check_without_httpx(method: str, url: str, headers: dict | None = None) -> Tuple[bool, str]:
    status, body = _request_with_urllib(method, url, headers=headers, timeout=5.0)
    ok = 200 <= status < 300
    return ok, f"{status} {body[:200]}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.environ.get("STRIDEON_HOST", "http://127.0.0.1:8000"), help="Base URL of backend, e.g. http://127.0.0.1:8000")
    parser.add_argument("--jwt", default=os.environ.get("STRIDEON_JWT", ""), help="Supabase JWT for auth endpoints (optional)")
    args = parser.parse_args()

    host = args.host.rstrip("/")
    jwt = args.jwt.strip()

    headers = {"Accept": "application/json"}
    if jwt:
        headers["Authorization"] = f"Bearer {jwt}"

    checks: List[Tuple[str, str, str, dict]] = []
    # Public endpoints
    checks.append(("GET", f"{host}/health", "/health", {}))
    checks.append(("GET", f"{host}/", "/", {}))

    # Very Network (optional but public)
    checks.append(("GET", f"{host}/verynet/health", "/verynet/health", {}))
    checks.append(("GET", f"{host}/verynet/leaderboard?count=5", "/verynet/leaderboard", {}))

    # Authenticated endpoints if JWT is provided
    if jwt:
        checks.append(("GET", f"{host}/profiles/me", "/profiles/me", {}))

    passed = 0
    failed = 0
    results: List[str] = []

    if httpx is not None:
        with httpx.Client(headers=headers) as client:  # type: ignore
            for method, url, name, kw in checks:
                ok, msg = check_with_httpx(client, method, url, **kw)
                if ok:
                    passed += 1
                    results.append(f"PASS {name} -> {msg}")
                else:
                    failed += 1
                    results.append(f"FAIL {name} -> {msg}")
    else:
        # Fallback using urllib
        for method, url, name, _ in checks:
            ok, msg = check_without_httpx(method, url, headers=headers)
            if ok:
                passed += 1
                results.append(f"PASS {name} -> {msg}")
            else:
                failed += 1
                results.append(f"FAIL {name} -> {msg}")

    print("\nStrideOn Backend — Smoke Test Results")
    print("=" * 44)
    for line in results:
        print(line)
    print("-" * 44)
    print(f"Summary: passed={passed} failed={failed} total={passed+failed}")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
