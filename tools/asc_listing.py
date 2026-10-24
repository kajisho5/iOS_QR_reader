#!/usr/bin/env python3
"""Apply appstore/listing.json to App Store Connect. Idempotent; prints each change (no secrets).

Sets: version string, copyright, category, content rights, subtitle, description, keywords, promotional text,
availability (the listed territories),
age rating (all "none"), App Review notes, the newest valid build, a free app price, and the In-App Purchase
localization, availability and review note. Things only the account holder can do (review contact name and phone,
submitting for review) are left alone. Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64, BUNDLE_ID.
"""
import json
import os
from pathlib import Path

from asc_app_urls import call

LISTING = json.loads((Path(__file__).resolve().parent.parent / "appstore" / "listing.json").read_text())

AGE_STRING_FIELDS = [
    "alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "gunsOrOtherWeapons",
    "medicalOrTreatmentInformation", "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity",
    "horrorOrFearThemes", "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
    "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic",
]
AGE_BOOL_FIELDS = [
    "advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat", "parentalControls",
    "ageAssurance", "socialMedia", "socialMediaAgeRestricted", "unrestrictedWebAccess", "userGeneratedContent",
]


def patch(kind, item_id, current, wanted, label, version="v1"):
    changes = {k: v for k, v in wanted.items() if current.get(k) != v}
    if not changes:
        print(f"{label}: already set")
        return
    call("PATCH", f"/{version}/{kind}/{item_id}", {"data": {"type": kind, "id": item_id, "attributes": changes}})
    for k, v in changes.items():
        shown = v if not isinstance(v, str) or len(v) <= 60 else v[:60] + "…"
        print(f"{label}: {k} -> {shown!r}")


def main():
    app = call("GET", "/v1/apps", **{"filter[bundleId]": os.environ["BUNDLE_ID"]})["data"][0]
    app_id = app["id"]
    patch("apps", app_id, app["attributes"], {"contentRightsDeclaration": LISTING["contentRightsDeclaration"]}, "app")

    # App info: category, age rating, subtitle.
    info = call("GET", f"/v1/apps/{app_id}/appInfos")["data"][0]
    category = call("GET", f"/v1/appInfos/{info['id']}/primaryCategory").get("data")
    if (category or {}).get("id") != LISTING["primaryCategory"]:
        call("PATCH", f"/v1/appInfos/{info['id']}", {"data": {"type": "appInfos", "id": info["id"], "relationships": {
            "primaryCategory": {"data": {"type": "appCategories", "id": LISTING["primaryCategory"]}}}}})
        print(f"appInfo: primaryCategory -> {LISTING['primaryCategory']}")
    else:
        print("appInfo: primaryCategory already set")
    age = call("GET", f"/v1/appInfos/{info['id']}/ageRatingDeclaration")["data"]
    wanted_age = {f: "NONE" for f in AGE_STRING_FIELDS} | {f: False for f in AGE_BOOL_FIELDS}
    patch("ageRatingDeclarations", age["id"], age["attributes"], wanted_age, "ageRating")
    for loc in call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]:
        texts = LISTING["localizations"].get(loc["attributes"]["locale"])
        if texts:
            patch("appInfoLocalizations", loc["id"], loc["attributes"], {"subtitle": texts["subtitle"]},
                  f"appInfoLocalization {loc['attributes']['locale']}")

    # The version being prepared: version string, copyright, texts, build, review details.
    versions = call("GET", f"/v1/apps/{app_id}/appStoreVersions", **{"filter[platform]": "IOS",
                                                                      "filter[appStoreState]": "PREPARE_FOR_SUBMISSION"})["data"]
    if not versions:
        raise SystemExit("No version in PREPARE_FOR_SUBMISSION")
    version = versions[0]
    patch("appStoreVersions", version["id"], version["attributes"],
          {"versionString": LISTING["versionString"], "copyright": LISTING["copyright"]}, "version")
    for loc in call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")["data"]:
        texts = LISTING["localizations"].get(loc["attributes"]["locale"])
        if texts:
            patch("appStoreVersionLocalizations", loc["id"], loc["attributes"],
                  {k: texts[k] for k in ("description", "keywords", "promotionalText")},
                  f"versionLocalization {loc['attributes']['locale']}")

    builds = call("GET", "/v1/builds", **{"filter[app]": app_id, "filter[processingState]": "VALID",
                                          "filter[preReleaseVersion.version]": LISTING["versionString"],
                                          "filter[expired]": "false", "sort": "-uploadedDate", "limit": "1"})["data"]
    current_build = call("GET", f"/v1/appStoreVersions/{version['id']}/build").get("data")
    if builds and (current_build or {}).get("id") != builds[0]["id"]:
        call("PATCH", f"/v1/appStoreVersions/{version['id']}/relationships/build",
             {"data": {"type": "builds", "id": builds[0]["id"]}})
        print(f"version: build -> {builds[0]['attributes']['version']}")
    else:
        print("version: build already set" if builds else "version: no valid build to attach")

    review = LISTING["review"]
    detail = call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail").get("data")
    if detail:
        patch("appStoreReviewDetails", detail["id"], detail["attributes"], review, "reviewDetail")
    else:
        # Apple requires the contact's name and phone number to create the review details; only the account
        # holder can enter those, so this waits until they have saved the contact in App Store Connect once.
        print("reviewDetail: not created yet (needs the contact name and phone in App Store Connect); notes are in listing.json")

    # Free app (the only purchase is the Pro In-App Purchase).
    try:
        has_price = bool(call("GET", f"/v1/appPriceSchedules/{app_id}/manualPrices").get("data"))
    except SystemExit:
        has_price = False  # 404 until a price has been set
    if has_price:
        print("price: already set (left as is)")
    else:
        points = call("GET", f"/v1/apps/{app_id}/appPricePoints", **{"filter[territory]": "JPN", "limit": "200"})["data"]
        free = next(p for p in points if float(p["attributes"]["customerPrice"]) == 0)
        call("POST", "/v1/appPriceSchedules", {
            "data": {"type": "appPriceSchedules", "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": "${free}"}]}}},
            "included": [{"type": "appPrices", "id": "${free}", "attributes": {"startDate": None},
                          "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free["id"]}}}}]})
        print("price: free (base territory JPN)")

    # Availability: only the listed territories, not new ones automatically.
    territories = LISTING["territories"]
    try:
        call("GET", f"/v1/apps/{app_id}/appAvailabilityV2")
        print("availability: already set (left as is)")
    except SystemExit:
        # Apple requires an entry for every territory: available only in the listed ones.
        everywhere = [t["id"] for t in call("GET", "/v1/territories", limit="200")["data"]]
        refs = [{"type": "territoryAvailabilities", "id": f"${{{t}}}"} for t in everywhere]
        call("POST", "/v2/appAvailabilities", {
            "data": {"type": "appAvailabilities", "attributes": {"availableInNewTerritories": False}, "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "territoryAvailabilities": {"data": refs}}},
            "included": [{"type": "territoryAvailabilities", "id": r["id"], "attributes": {"available": t in territories},
                          "relationships": {"territory": {"data": {"type": "territories", "id": t}}}}
                         for r, t in zip(refs, everywhere)]})
        print(f"availability: {', '.join(territories)}")

    # In-App Purchase: localization and review note.
    iap_cfg = LISTING["inAppPurchase"]
    iap = next(i for i in call("GET", f"/v1/apps/{app_id}/inAppPurchasesV2")["data"]
               if i["attributes"]["productId"] == iap_cfg["productId"])
    patch("inAppPurchases", iap["id"], iap["attributes"], {"reviewNote": iap_cfg["reviewNote"]}, "IAP", version="v2")
    existing = {l["attributes"]["locale"]: l for l in call("GET", f"/v2/inAppPurchases/{iap['id']}/inAppPurchaseLocalizations")["data"]}
    for locale, texts in iap_cfg["localizations"].items():
        if locale in existing:
            patch("inAppPurchaseLocalizations", existing[locale]["id"], existing[locale]["attributes"], texts, f"IAP localization {locale}")
        else:
            call("POST", "/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations",
                 "attributes": {"locale": locale, **texts},
                 "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap["id"]}}}}})
            print(f"IAP localization {locale}: created")
    try:
        current = {t["id"] for t in call("GET", f"/v1/inAppPurchaseAvailabilities/{iap['id']}/availableTerritories",
                                             limit="200").get("data", [])}
    except SystemExit:
        current = set()  # 404 until availability has been set
    if current != set(territories):
        call("POST", "/v1/inAppPurchaseAvailabilities", {"data": {"type": "inAppPurchaseAvailabilities",
             "attributes": {"availableInNewTerritories": False}, "relationships": {
                 "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap["id"]}},
                 "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]}}}})
        print(f"IAP availability: {', '.join(territories)}")
    else:
        print("IAP availability: already set")
    print("IAP state:", call("GET", f"/v2/inAppPurchases/{iap['id']}")["data"]["attributes"]["state"])


if __name__ == "__main__":
    main()
