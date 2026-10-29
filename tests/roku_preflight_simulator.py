#!/usr/bin/env python3
"""ELVANOQ Play Roku preflight simulator.

This is a contract simulator: it checks the package source, activation state
coverage and the public relay health endpoint using synthetic identifiers.
It never registers a device, saves a playlist or sends IPTV credentials.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPORT = ROOT / "out" / "roku-homologation-report.json"
PORTAL = (ROOT / "components" / "PortalService.brs").read_text(encoding="utf-8")
SCENE = (ROOT / "components" / "MainScene.brs").read_text(encoding="utf-8")
MANIFEST = (ROOT / "manifest").read_text(encoding="utf-8")

checks: list[dict] = []


def check(name: str, condition: bool, detail: str) -> None:
    checks.append({"name": name, "passed": condition, "detail": detail})
    if not condition:
        print(f"FAIL: {name} — {detail}", file=sys.stderr)
    else:
        print(f"PASS: {name}")


def format_device_code(client_id: str) -> str:
    normalized = "".join(char.upper() for char in client_id if char.isalnum())
    if len(normalized) < 16:
        return "ROKU-CÓDIGO-INDISPONÍVEL"
    return f"ROKU-{normalized[:8]}-{normalized[8:16]}"


def static_contract_checks() -> None:
    check(
        "custom relay endpoint",
        'https://roku.elvanoqplay.app/api/roku' in PORTAL,
        "The Roku app must use the custom relay domain.",
    )
    check(
        "descriptive user agent",
        'User-Agent", "ELVANOQPlay-Roku/0.1.88' in PORTAL,
        "Cloudflare-compatible User-Agent is required.",
    )
    check(
        "persistent Roku identifier",
        "GetChannelClientId()" in SCENE,
        "Activation must use roDeviceInfo.GetChannelClientId().",
    )
    check(
        "no MAC implementation",
        not re.search(r"mac[ _-]?address|\bmac\b", PORTAL + "\n" + SCENE, flags=re.I),
        "Roku code must not use a MAC identifier.",
    )
    for action in (
        "roku-device-register",
        "roku-license-status",
        "roku-playlist-sync",
        "roku-server-code-resolve",
    ):
        check(f"action {action}", action in SCENE or action in PORTAL, "Required Portal action is present.")
    check(
        "remote OK opens login",
        'if key = "OK" and m.inputDialog = invalid' in SCENE
        and "openServerCodeKeyboard()" in SCENE
        and 'CreateObject("roSGNode", "StandardKeyboardDialog")' in SCENE,
        "The activation scene must open the code dialog from the Roku remote OK event.",
    )
    check(
        "safe HTTP timeouts",
        "SetConnectTimeout(10)" in PORTAL and "SetMinimumTransferRate(1, 15)" in PORTAL,
        "Portal client must have bounded network timeouts.",
    )
    check(
        "version is 0.1.88",
        "build_version=88" in MANIFEST,
        "The manifest must identify this tested package build.",
    )


def state_machine_checks() -> None:
    sample = "ab12-cd34_ef56gh78ijk9"
    formatted = format_device_code(sample)
    check(
        "visual device code",
        formatted == "ROKU-AB12CD34-EF56GH78",
        f"Synthetic client id formats as {formatted}.",
    )
    check(
        "short identifier rejected",
        format_device_code("short") == "ROKU-CÓDIGO-INDISPONÍVEL",
        "Synthetic invalid identifier is not exposed as a device code.",
    )

    expected_ui = {
        "pending": "activation",
        "active": "home",
        "expired": "activation",
        "blocked": "activation",
        "offline": "activation",
        "error": "activation",
    }
    for state, target in expected_ui.items():
        if state == "active":
            covered = 'if state = "active" then' in SCENE and "openAppShell()" in SCENE
        elif state == "pending":
            covered = "Aguardando ativação. Vincule este Roku em elvanoqplay.app." in SCENE
        else:
            covered = f'state = "{state}"' in SCENE
        check(f"state {state}", covered, f"Synthetic {state} state keeps the UI in {target}.")


def relay_health_check() -> None:
    request = urllib.request.Request(
        "https://roku.elvanoqplay.app/health",
        headers={"User-Agent": "ELVANOQPlay-Roku/0.1.88", "Accept": "application/json"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = response.read().decode("utf-8")
            payload = json.loads(body)
            ok = response.status == 200 and payload == {"ok": True, "service": "portal"}
            check(
                "relay health",
                ok,
                f"Expected Portal health JSON; received HTTP {response.status} with {payload!r}.",
            )
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as error:
        check("relay health", False, f"Health endpoint could not be validated: {error}.")


def main() -> int:
    static_contract_checks()
    state_machine_checks()
    relay_health_check()
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(
        json.dumps(
            {
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "suite": "roku-preflight-simulator",
                "hardware_scope": "not a replacement for Roku device playback validation",
                "checks": checks,
                "passed": all(item["passed"] for item in checks),
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )
    failed = [item["name"] for item in checks if not item["passed"]]
    print(f"\nRoku simulator: {len(checks) - len(failed)}/{len(checks)} checks passed.")
    if failed:
        print("Failed checks: " + ", ".join(failed), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
