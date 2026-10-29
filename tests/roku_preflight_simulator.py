#!/usr/bin/env python3
"""ELVANOQ Play Roku behavioral preflight simulator.

This is a deterministic CI simulator. It validates source contracts plus the
activation, remote-login and playlist state machines using synthetic data.
It never registers a device, stores a playlist, or transmits credentials.

It is not a replacement for validation on a physical Roku: video playback,
remote focus implementation and roDeviceInfo values must still be exercised
on Roku OS.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPORT = ROOT / "out" / "roku-homologation-report.json"
PORTAL = (ROOT / "components" / "PortalService.brs").read_text(encoding="utf-8")
NETWORK_SERVICES = {
    name: (ROOT / "components" / name).read_text(encoding="utf-8")
    for name in ("PortalService.brs", "CatalogService.brs", "EpgService.brs", "MetadataService.brs")
}
SCENE = (ROOT / "components" / "MainScene.brs").read_text(encoding="utf-8")
MANIFEST = (ROOT / "manifest").read_text(encoding="utf-8")

checks: list[dict] = []


def check(name: str, condition: bool, detail: str) -> None:
    checks.append({"name": name, "passed": condition, "detail": detail})
    print(("PASS" if condition else "FAIL") + f": {name}" + ("" if condition else f" — {detail}"), file=sys.stderr if not condition else sys.stdout)


def format_device_code(client_id: str) -> str:
    normalized = "".join(char.upper() for char in client_id if char.isalnum())
    if len(normalized) < 16:
        return "ROKU-CÓDIGO-INDISPONÍVEL"
    return f"ROKU-{normalized[:8]}-{normalized[8:16]}"


@dataclass
class SyntheticRoku:
    """Small behavioral model of the user-visible Roku activation flow."""

    screen: str = "activation"
    dialog: str | None = None
    status: str = "pending"
    playlist_applied: bool = False
    requests: list[str] = field(default_factory=list)

    def boot(self) -> None:
        self.requests.append("roku-device-register")

    def portal_result(self, action: str, ok: bool, state: str = "pending") -> None:
        if action == "roku-device-register":
            if ok:
                self.requests.append("roku-license-status")
            else:
                self.status = state
            return
        if action == "roku-license-status":
            self.status = state
            if ok and state == "active":
                self.screen = "home"
                self.requests.append("roku-playlist-sync")
            else:
                self.screen = "activation"
            return
        if action == "roku-playlist-sync" and ok and self.screen == "home":
            self.playlist_applied = True

    def press_ok(self) -> bool:
        if self.screen != "activation" or self.dialog is not None:
            return False
        self.dialog = "server_code"
        return True

    def submit_server_code(self, valid: bool) -> None:
        self.dialog = "username" if valid else None
        self.status = "validating-code" if valid else "invalid-code"

    def submit_username(self, present: bool) -> None:
        self.dialog = "password" if present else None

    def submit_password(self, present: bool) -> None:
        if present:
            self.dialog = None
            self.screen = "home"
        else:
            self.dialog = None
            self.screen = "activation"


def static_contract_checks() -> None:
    check("custom relay endpoint", 'https://roku.elvanoqplay.app/api/roku' in PORTAL, "App must use custom Roku relay.")
    check("descriptive user agent", 'User-Agent", "ELVANOQPlay-Roku/0.1.88' in PORTAL, "Cloudflare-compatible agent is required.")
    check("persistent Roku identifier", "GetChannelClientId()" in SCENE, "Activation must use roDeviceInfo.GetChannelClientId().")
    check("no MAC implementation", not re.search(r"mac[ _-]?address|\\bmac\\b", PORTAL + "\n" + SCENE, flags=re.I), "Roku must not use MAC.")
    for action in ("roku-device-register", "roku-license-status", "roku-playlist-sync", "roku-server-code-resolve"):
        check(f"action {action}", action in SCENE or action in PORTAL, "Required Portal action is present.")
    check(
        "remote focus and OK are consumed",
        "m.top.setFocus(true)" in SCENE
        and 'if key = "OK" and m.inputDialog = invalid then' in SCENE
        and "openServerCodeKeyboard()" in SCENE
        and "return true" in SCENE,
        "Activation scene must own focus and consume Roku OK.",
    )
    check(
        "server code dialog is wired",
        'CreateObject("roSGNode", "StandardKeyboardDialog")' in SCENE
        and 'dialog.observeField("buttonSelected", "onServerCodeKeyboardSelected")' in SCENE
        and "sub onServerCodeKeyboardSelected()" in SCENE,
        "Remote OK must create and handle the code dialog.",
    )
    check(
        "credential sequence is wired",
        'openCredentialKeyboard("username")' in SCENE
        and "sub onUsernameKeyboardSelected()" in SCENE
        and "sub onPasswordKeyboardSelected()" in SCENE,
        "Resolved server code must lead to username/password dialogs.",
    )
    check(
        "active sync flow is wired",
        'requestPortal("roku-license-status")' in SCENE
        and 'requestPortal("roku-playlist-sync")' in SCENE
        and 'm.appShell.callFunc("applyPlaylist", result.payload)' in SCENE,
        "Active license must request and apply the Portal playlist.",
    )
    check(
        "HTTP host allowed for IPTV",
        'left(lower, 7) <> "http://"' in SCENE and 'left(lower, 8) <> "https://"' in SCENE,
        "Resolved IPTV host accepts HTTP and HTTPS.",
    )
    check(
        "Roku-compatible HTTP timeouts",
        all("SetConnectTimeout" not in source for source in NETWORK_SERVICES.values())
        and "SetMinimumTransferRate(1, 15)" in PORTAL
        and "AsyncPostFromString" in PORTAL
        and 'CreateObject("roMessagePort")' in PORTAL
        and "wait(20000, port)" in PORTAL
        and "transfer.AsyncCancel()" in PORTAL,
        "All services must avoid unsupported SetConnectTimeout and Portal must bound asynchronous requests.",
    )
    check(
        "descriptive Portal HTTP errors",
        "portalHttpMessage" in PORTAL and "(HTTP " in PORTAL,
        "Portal errors must surface the response message and HTTP status.",
    )
    check("version is 0.1.88", "build_version=88" in MANIFEST, "Manifest must match this tested build.")


def state_machine_checks() -> None:
    check("visual device code", format_device_code("ab12-cd34_ef56gh78ijk9") == "ROKU-AB12CD34-EF56GH78", "Synthetic client id must have exact Roku code format.")
    check("short identifier rejected", format_device_code("short") == "ROKU-CÓDIGO-INDISPONÍVEL", "Bad synthetic id must never be displayed as usable.")

    pending = SyntheticRoku()
    pending.boot()
    pending.portal_result("roku-device-register", True)
    pending.portal_result("roku-license-status", False, "pending")
    check("pending remains activation", pending.screen == "activation" and pending.status == "pending", "Unlinked device must not enter Home.")

    active = SyntheticRoku()
    active.boot()
    active.portal_result("roku-device-register", True)
    active.portal_result("roku-license-status", True, "active")
    active.portal_result("roku-playlist-sync", True, "active")
    check("active opens Home and applies saved playlist", active.screen == "home" and active.playlist_applied and active.requests == ["roku-device-register", "roku-license-status", "roku-playlist-sync"], "Active license must load the saved list.")

    retry = SyntheticRoku()
    retry.boot()
    retry.portal_result("roku-device-register", False, "offline")
    retry.boot()
    retry.portal_result("roku-device-register", True)
    retry.portal_result("roku-license-status", True, "active")
    check("offline can recover on retry", retry.screen == "home" and retry.status == "active", "A transient network failure must not permanently lock the activation UI.")

    for terminal in ("expired", "blocked", "error"):
        device = SyntheticRoku()
        device.boot()
        device.portal_result("roku-device-register", False, terminal)
        check(f"{terminal} remains activation", device.screen == "activation" and device.status == terminal, "Non-active license state must not expose Home.")

    login = SyntheticRoku()
    opened = login.press_ok()
    login.submit_server_code(True)
    login.submit_username(True)
    login.submit_password(True)
    check("remote code login opens dialogs then Home", opened and login.screen == "home" and login.dialog is None, "OK flow must progress server code → username → password.")

    invalid = SyntheticRoku()
    invalid.press_ok()
    invalid.submit_server_code(False)
    check("invalid server code returns to activation", invalid.screen == "activation" and invalid.dialog is None and invalid.status == "invalid-code", "Invalid code must not expose Home.")


def relay_health_check() -> None:
    request = urllib.request.Request(
        "https://roku.elvanoqplay.app/health",
        headers={"User-Agent": "ELVANOQPlay-Roku/0.1.88", "Accept": "application/json"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            payload = json.loads(response.read().decode("utf-8"))
            check("relay health", response.status == 200 and payload == {"ok": True, "service": "portal"}, f"Expected Portal health JSON; received HTTP {response.status} with {payload!r}.")
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as error:
        check("relay health", False, f"Health endpoint could not be validated: {error}.")


def main() -> int:
    static_contract_checks()
    state_machine_checks()
    relay_health_check()
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "suite": "roku-behavioral-preflight-simulator",
        "hardware_scope": "not a replacement for physical Roku OS playback and focus validation",
        "checks": checks,
        "passed": all(item["passed"] for item in checks),
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    failed = [item["name"] for item in checks if not item["passed"]]
    print(f"\nRoku simulator: {len(checks) - len(failed)}/{len(checks)} checks passed.")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
