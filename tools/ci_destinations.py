#!/usr/bin/env python3
"""Print xcodebuild destinations for the newest available simulators as KEY=VALUE lines.

Usage: xcrun simctl list devices available -j | python3 tools/ci_destinations.py [MAX_IOS]
MAX_IOS (e.g. 26.5) skips runtimes newer than the selected Xcode's SDK.
Exits with status 1 when no iPhone simulator is available.
"""
import json
import re
import sys

max_version = tuple(map(int, sys.argv[1].split("."))) if len(sys.argv) > 1 else None
devices = json.load(sys.stdin)["devices"]


def version(runtime):
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return tuple(map(int, match.groups())) if match else None


runtimes = sorted((v, r) for r in devices if (v := version(r)) and (max_version is None or v <= max_version))


def newest(prefix, duo=False):
    for v, runtime in reversed(runtimes):
        names = [d["name"] for d in devices[runtime]
                 if d["name"].startswith(prefix) and (("Duo" in d["name"]) == duo)]
        if names:
            return f"platform=iOS Simulator,name={names[-1]},OS={v[0]}.{v[1]}"
    return None


iphone, ipad, duo = newest("iPhone"), newest("iPad"), newest("iPhone", duo=True)
if iphone is None:
    sys.exit(1)
print(f"IPHONE_DESTINATION={iphone}")
if ipad:
    print(f"IPAD_DESTINATION={ipad}")
if duo:
    print(f"DUO_DESTINATION={duo}")
