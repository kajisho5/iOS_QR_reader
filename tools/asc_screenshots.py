#!/usr/bin/env python3
"""Upload App Store screenshots and the In-App Purchase review screenshot (replaces what is there).

Usage: python3 asc_screenshots.py DIR
DIR holds appstore-iphone-NN-*.png (1320x2868), appstore-ipad-NN-*.png (2064x2752) and iap-review.png.
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64, BUNDLE_ID, LOCALE (default ja), IAP_PRODUCT_ID.
"""
import hashlib
import os
import struct
import sys
import urllib.request
from pathlib import Path

from asc_app_urls import call

DISPLAY_TYPES = {
    "iphone": ("APP_IPHONE_67", {(1320, 2868), (1290, 2796)}),
    "ipad": ("APP_IPAD_PRO_3GEN_129", {(2064, 2752), (2048, 2732)}),
}


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def upload(kind, create_body, path):
    """Reserve, upload the bytes to Apple's storage, then commit with the MD5 checksum."""
    data = path.read_bytes()
    create_body["data"]["attributes"] = {"fileName": path.name, "fileSize": len(data)}
    created = call("POST", f"/v1/{kind}", create_body)["data"]
    for op in created["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"],
                                     headers={h["name"]: h["value"] for h in op["requestHeaders"]})
        with urllib.request.urlopen(req, timeout=120):
            pass
    call("PATCH", f"/v1/{kind}/{created['id']}", {"data": {"type": kind, "id": created["id"],
         "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    print(f"uploaded {path.name}")


def main():
    folder = Path(sys.argv[1])
    locale = os.environ.get("LOCALE", "ja")
    app = call("GET", "/v1/apps", **{"filter[bundleId]": os.environ["BUNDLE_ID"]})["data"][0]
    version = call("GET", f"/v1/apps/{app['id']}/appStoreVersions", **{"filter[platform]": "IOS",
                   "filter[appStoreState]": "PREPARE_FOR_SUBMISSION"})["data"][0]
    loc = next(l for l in call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")["data"]
               if l["attributes"]["locale"] == locale)
    sets = {s["attributes"]["screenshotDisplayType"]: s
            for s in call("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]}

    for device, (display_type, sizes) in DISPLAY_TYPES.items():
        files = sorted(folder.glob(f"appstore-{device}-*.png"))
        bad = [f.name for f in files if png_size(f) not in sizes]
        if not files or bad:
            print(f"{device}: skipped ({'no files' if not files else 'wrong size: ' + ', '.join(bad)})")
            continue
        screenshot_set = sets.get(display_type)
        if screenshot_set:
            for old in call("GET", f"/v1/appScreenshotSets/{screenshot_set['id']}/appScreenshots")["data"]:
                call("DELETE", f"/v1/appScreenshots/{old['id']}")
                print(f"{device}: removed {old['attributes'].get('fileName')}")
        else:
            screenshot_set = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                                  "attributes": {"screenshotDisplayType": display_type},
                                  "relationships": {"appStoreVersionLocalization": {"data": {
                                      "type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]
        for f in files:
            upload("appScreenshots", {"data": {"type": "appScreenshots", "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": screenshot_set["id"]}}}}}, f)

    review = folder / "iap-review.png"
    product_id = os.environ.get("IAP_PRODUCT_ID")
    if review.exists() and product_id:
        iap = next(i for i in call("GET", f"/v1/apps/{app['id']}/inAppPurchasesV2")["data"]
                   if i["attributes"]["productId"] == product_id)
        old = call("GET", f"/v2/inAppPurchases/{iap['id']}/appStoreReviewScreenshot").get("data")
        if old:
            call("DELETE", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{old['id']}")
            print("IAP: removed the old review screenshot")
        upload("inAppPurchaseAppStoreReviewScreenshots", {"data": {"type": "inAppPurchaseAppStoreReviewScreenshots",
               "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap["id"]}}}}}, review)


if __name__ == "__main__":
    main()
