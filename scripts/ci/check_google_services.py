"""
CI helper for build-apk.yml — validates that android/app/google-services.json
contains an Android OAuth client whose `certificate_hash` matches the
pinned debug keystore SHA-1 the APK is being signed with.

Two modes:

  sync   — Reads the just-downloaded Firebase config (the response from
           androidApps/.../config, JSON with a base64-encoded
           `configFileContents`) and only overwrites the committed
           google-services.json when the downloaded copy DOES contain
           the expected SHA. Prevents Firebase's eventual-consistency
           lag from blowing away a known-good config.

  verify — After sync, sanity-checks the on-disk google-services.json.
           Exits non-zero if it still doesn't list the keystore SHA,
           so the CI build fails loudly instead of producing a silently
           broken APK that only the end user discovers (client
           2026-05-19 #1).

Usage:
    python3 check_google_services.py sync <api_response_path>
    python3 check_google_services.py verify

Env:
    SHA1_FINGERPRINT  — the keystore SHA-1 (colon-separated or not).
"""
import base64
import json
import os
import sys

CONFIG_PATH = "android/app/google-services.json"


def _normalise(sha: str) -> str:
    return sha.replace(":", "").lower()


def _hashes(cfg: dict) -> set[str]:
    out = set()
    for entry in cfg.get("client", []):
        for oc in entry.get("oauth_client", []):
            h = (oc.get("android_info") or {}).get("certificate_hash")
            if h:
                out.add(h.lower())
    return out


def _expected_sha() -> str:
    return _normalise(os.environ.get("SHA1_FINGERPRINT", ""))


def _sync(api_response_path: str) -> int:
    expected = _expected_sha()
    with open(api_response_path, encoding="utf-8") as fh:
        wrapper = json.load(fh)
    decoded = base64.b64decode(wrapper["configFileContents"])
    incoming = json.loads(decoded)
    incoming_hashes = _hashes(incoming)
    if expected and expected not in incoming_hashes:
        print(
            f"Synced config is missing OAuth client for SHA {expected} "
            f"(only has {sorted(incoming_hashes)}). Keeping committed "
            "google-services.json - Firebase backend still propagating.",
            flush=True,
        )
        return 0
    with open(CONFIG_PATH, "wb") as fh:
        fh.write(decoded)
    print(
        f"google-services.json synced (contains OAuth client for {expected}).",
        flush=True,
    )
    return 0


def _verify() -> int:
    expected = _expected_sha()
    with open(CONFIG_PATH, encoding="utf-8") as fh:
        cfg = json.load(fh)
    on_disk = _hashes(cfg)
    if expected and expected not in on_disk:
        print(
            "::error::google-services.json is missing OAuth client for "
            f"keystore SHA {expected}. Got: {sorted(on_disk)}. "
            "Google Sign-In WILL fail on this APK.",
            flush=True,
        )
        return 1
    print(
        f"google-services.json verified to contain OAuth client for {expected}.",
        flush=True,
    )
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: check_google_services.py {sync|verify} [path]", file=sys.stderr)
        return 2
    mode = argv[1]
    if mode == "sync":
        if len(argv) < 3:
            print("sync mode requires the api response path", file=sys.stderr)
            return 2
        return _sync(argv[2])
    if mode == "verify":
        return _verify()
    print(f"unknown mode: {mode}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
