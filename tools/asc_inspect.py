#!/usr/bin/env python3
"""Print what is set for the App Store listing (read-only, no secrets printed).

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64, BUNDLE_ID.
"""
import json
import os

from asc_app_urls import call


def show(title, obj):
    print(f"\n== {title}")
    print(json.dumps(obj, ensure_ascii=False, indent=1)[:3000])


def attrs(res):
    data = res.get("data")
    if isinstance(data, list):
        return [{"id": d["id"], **d.get("attributes", {})} for d in data]
    return {"id": data["id"], **data.get("attributes", {})} if data else None


def safe(path, **query):
    try:
        return call("GET", path, **query)
    except SystemExit as e:
        print(f"(skip) {e}")
        return {}


def main():
    app = call("GET", "/v1/apps", **{"filter[bundleId]": os.environ["BUNDLE_ID"]})["data"][0]
    show("app", {k: v for k, v in app["attributes"].items()})
    info = call("GET", f"/v1/apps/{app['id']}/appInfos")["data"][0]
    show("appInfo", attrs({"data": info}))
    for rel in ("primaryCategory", "secondaryCategory", "ageRatingDeclaration"):
        show(f"appInfo.{rel}", attrs(safe(f"/v1/appInfos/{info['id']}/{rel}")))
    show("appInfoLocalizations", attrs(safe(f"/v1/appInfos/{info['id']}/appInfoLocalizations")))
    versions = call("GET", f"/v1/apps/{app['id']}/appStoreVersions")["data"]
    for v in versions:
        show(f"version {v['attributes'].get('versionString')}", attrs({"data": v}))
        show("version.build", attrs(safe(f"/v1/appStoreVersions/{v['id']}/build")))
        show("version.reviewDetail", attrs(safe(f"/v1/appStoreVersions/{v['id']}/appStoreReviewDetail")))
        for loc in safe(f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations").get("data", []):
            show(f"versionLocalization {loc['attributes'].get('locale')}", attrs({"data": loc}))
            sets = safe(f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets").get("data", [])
            show("screenshotSets", [s["attributes"] for s in sets])
            for screenshot_set in sets:
                shots = safe(f"/v1/appScreenshotSets/{screenshot_set['id']}/appScreenshots").get("data", [])
                show(f"screenshots {screenshot_set['attributes']['screenshotDisplayType']}",
                     [(x["attributes"].get("fileName"), (x["attributes"].get("assetDeliveryState") or {}).get("state")) for x in shots])
    show("priceSchedule", safe(f"/v1/apps/{app['id']}/appPriceSchedule"))
    show("priceSchedule.manualPrices", safe(f"/v1/appPriceSchedules/{app['id']}/manualPrices", include="appPricePoint"))
    show("availability", attrs(safe(f"/v1/apps/{app['id']}/appAvailabilityV2")))
    iaps = safe(f"/v1/apps/{app['id']}/inAppPurchasesV2").get("data", [])
    for iap in iaps:
        show(f"IAP {iap['attributes'].get('productId')}", attrs({"data": iap}))
        show("IAP.localizations", attrs(safe(f"/v2/inAppPurchases/{iap['id']}/inAppPurchaseLocalizations")))
        show("IAP.manualPrices", safe(f"/v1/inAppPurchasePriceSchedules/{iap['id']}/manualPrices", include="inAppPurchasePricePoint"))
        show("IAP.availability", safe(f"/v2/inAppPurchases/{iap['id']}/inAppPurchaseAvailability"))
        review = attrs(safe(f"/v2/inAppPurchases/{iap['id']}/appStoreReviewScreenshot"))
        show("IAP.reviewScreenshot", review and {"fileName": review.get("fileName"), "state": (review.get("assetDeliveryState") or {}).get("state")})
    show("builds", [{"version": b["attributes"].get("version"), "state": b["attributes"].get("processingState")}
                    for b in safe("/v1/builds", **{"filter[app]": app["id"], "limit": "3", "sort": "-uploadedDate"}).get("data", [])])


if __name__ == "__main__":
    main()
