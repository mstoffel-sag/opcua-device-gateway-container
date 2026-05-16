#!/usr/bin/env python3
"""Update opcua_version entries in .github/workflows/publish.yaml.

Behaviour:
- Same major (e.g. 1023.2.1 -> 1023.3.0):
    All opcua_version entries in the matrix are bumped.
- New major (e.g. 1023.2.1 -> 1024.0.0):
    Only the generic `opcua-device-gateway` entry is updated.
    A new major-version-pinned entry (e.g. `opcua-device-gateway-1024`) is added.
    The old major-version entry (e.g. `opcua-device-gateway-1023`) is frozen.

Usage:
    python3 update_opcua_version.py --get-current
        Print the current version from publish.yaml and exit.

    LATEST=x.y.z CURRENT=a.b.c LATEST_MAJOR=x CURRENT_MAJOR=a \\
        python3 update_opcua_version.py
        Update publish.yaml in-place.
"""

import os
import re
import sys

PUBLISH_YAML = ".github/workflows/publish.yaml"


def get_current():
    with open(PUBLISH_YAML) as f:
        content = f.read()
    m = re.search(r'opcua_version: "([^"]+)"\s+image: opcua-device-gateway\n', content)
    if not m:
        print(f"ERROR: could not find the generic opcua-device-gateway entry in {PUBLISH_YAML}", file=sys.stderr)
        sys.exit(1)
    print(m.group(1))


def update():
    latest = os.environ["LATEST"]
    current = os.environ["CURRENT"]
    latest_major = os.environ["LATEST_MAJOR"]
    current_major = os.environ["CURRENT_MAJOR"]

    with open(PUBLISH_YAML) as f:
        content = f.read()

    if latest_major == current_major:
        # Same major: bump ALL opcua_version entries in the matrix.
        updated = content.replace(f'opcua_version: "{current}"', f'opcua_version: "{latest}"')
        if updated == content:
            print(f'ERROR: could not find opcua_version: "{current}" in {PUBLISH_YAML}', file=sys.stderr)
            sys.exit(1)
        content = updated
    else:
        # New major:
        # Step 1 – update only the generic entry (image name has no major suffix).
        pattern = (
            r'(- opcua_version: )"'
            + re.escape(current)
            + r'"(\s+image: opcua-device-gateway\n)'
        )
        content, n = re.subn(
            pattern,
            lambda m: m.group(1) + f'"{latest}"' + m.group(2),
            content,
        )
        if n == 0:
            print(f"ERROR: could not locate the generic opcua-device-gateway entry in {PUBLISH_YAML}", file=sys.stderr)
            sys.exit(1)

        # Step 2 – insert a new major-version-pinned entry right after the generic one.
        #   10 spaces match the existing `- opcua_version:` indentation in publish.yaml.
        indent = "          "
        new_entry = (
            f'\n{indent}- opcua_version: "{latest}"\n'
            f"{indent}  image: opcua-device-gateway-{latest_major}\n"
        )
        marker = "image: opcua-device-gateway\n"
        pos = content.find(marker)
        if pos == -1:
            print(f"ERROR: could not find insertion point in {PUBLISH_YAML}", file=sys.stderr)
            sys.exit(1)
        pos += len(marker)
        content = content[:pos] + new_entry + content[pos:]

    with open(PUBLISH_YAML, "w") as f:
        f.write(content)

    print(f"Updated {PUBLISH_YAML}: {current} -> {latest}")


if __name__ == "__main__":
    if "--get-current" in sys.argv:
        get_current()
    else:
        update()
