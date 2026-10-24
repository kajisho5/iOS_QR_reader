#!/usr/bin/env python3
"""Set the App Store Connect URLs (privacy policy, support, marketing) for every localization. Idempotent.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64, BUNDLE_ID, PRIVACY_URL, SUPPORT_URL, MARKETING_URL.
App Privacy (data collection answers) has no public API and must be set in App Store Connect on the web.
"""
import json
import os
import time
import urllib.parse
import urllib.request

import jwt

from asc_status import API, pem

EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}


def call(method, path, body=None, **query):
    now = int(time.time())
    token = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"].strip(), "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
                       pem(), algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"].strip(), "typ": "JWT"})
    url = API + path + ("?" + urllib.parse.urlencode(query) if query else "")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as res:
            raw = res.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> HTTP {e.code}: {e.read().decode(errors='replace')[:1500]}")


def update(kind, item, wanted):
    current = {k: item["attributes"].get(k) for k in wanted}
    changes = {k: v for k, v in wanted.items() if current[k] != v}
    label = f"{kind} {item['attributes'].get('locale')}"
    if not changes:
        print(f"{label}: already set")
        return
    call("PATCH", f"/v1/{kind}/{item['id']}", {"data": {"type": kind, "id": item["id"], "attributes": changes}})
    for k, v in changes.items():
        print(f"{label}: {k} {current[k]!r} -> {v!r}")


def main():
    apps = call("GET", "/v1/apps", **{"filter[bundleId]": os.environ["BUNDLE_ID"]}).get("data", [])
    if not apps:
        raise SystemExit(f"No App Store Connect app for {os.environ['BUNDLE_ID']}")
    app = apps[0]
    print(f"App: {app['attributes'].get('name')} ({app['id']}), primary locale {app['attributes'].get('primaryLocale')}")

    # Privacy policy URL lives on the app info (editable while the app info is not live-only).
    infos = call("GET", f"/v1/apps/{app['id']}/appInfos").get("data", [])
    edited_info = False
    for info in infos:
        state = info["attributes"].get("appStoreState") or info["attributes"].get("state")
        locs = call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations").get("data", [])
        print(f"appInfo {info['id']} state={state} localizations={len(locs)}")
        if state in ("READY_FOR_SALE", "READY_FOR_DISTRIBUTION") and len(infos) > 1:
            continue
        for loc in locs:
            update("appInfoLocalizations", loc, {"privacyPolicyUrl": os.environ["PRIVACY_URL"]})
            edited_info = True
    if not edited_info:
        print("No editable app info found")

    # Support and marketing URLs live on the version being prepared.
    versions = call("GET", f"/v1/apps/{app['id']}/appStoreVersions", **{"filter[platform]": "IOS"}).get("data", [])
    editable = [v for v in versions if (v["attributes"].get("appStoreState") or v["attributes"].get("appVersionState")) in EDITABLE]
    for v in versions:
        print(f"version {v['attributes'].get('versionString')} state={v['attributes'].get('appStoreState')}")
    if not editable:
        raise SystemExit("No editable App Store version (create version 1.0.0 in App Store Connect first)")
    for v in editable:
        for loc in call("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations").get("data", []):
            update("appStoreVersionLocalizations", loc,
                   {"supportUrl": os.environ["SUPPORT_URL"], "marketingUrl": os.environ["MARKETING_URL"]})


if __name__ == "__main__":
    main()
