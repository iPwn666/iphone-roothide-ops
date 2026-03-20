#!/usr/bin/env python3
from __future__ import annotations

import argparse
import plistlib
import sys
import zipfile
from pathlib import Path


def find_app_dir(root: Path) -> Path:
    payload = root / "Payload"
    if not payload.exists():
        raise SystemExit("Payload directory not found")
    apps = sorted(payload.glob("*.app"))
    if not apps:
        raise SystemExit("No .app bundle found under Payload/")
    return apps[0]


def inspect_archive(path: Path) -> int:
    with zipfile.ZipFile(path) as zf:
        app_plists = [n for n in zf.namelist() if n.startswith("Payload/") and n.endswith(".app/Info.plist")]
        if not app_plists:
            raise SystemExit("No app Info.plist found in archive")
        info = plistlib.loads(zf.read(app_plists[0]))
        print(f"archive={path}")
        print(f"bundle_id={info.get('CFBundleIdentifier', 'UNKNOWN')}")
        print(f"bundle_name={info.get('CFBundleDisplayName') or info.get('CFBundleName') or 'UNKNOWN'}")
        print(f"bundle_version={info.get('CFBundleShortVersionString', 'UNKNOWN')}")
        print(f"build_version={info.get('CFBundleVersion', 'UNKNOWN')}")
        extensions = sorted(
            {
                n.split("/")[2]
                for n in zf.namelist()
                if n.startswith("Payload/") and ".app/PlugIns/" in n and n.endswith(".appex/Info.plist")
            }
        )
        print(f"extensions={','.join(extensions) if extensions else 'NONE'}")
    return 0


def unpack_archive(path: Path, output: Path) -> int:
    output.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path) as zf:
        zf.extractall(output)
    app_dir = find_app_dir(output)
    print(f"unpacked_to={output}")
    print(f"app_bundle={app_dir}")
    return 0


def repack_archive(source: Path, output: Path) -> int:
    if not (source / "Payload").exists():
        raise SystemExit("Source directory must contain Payload/")
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp_output = output.with_suffix(output.suffix + ".tmp")
    if tmp_output.exists():
        tmp_output.unlink()
    with zipfile.ZipFile(tmp_output, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for item in sorted(source.rglob("*")):
            if item.is_file():
                zf.write(item, item.relative_to(source))
    tmp_output.replace(output)
    print(f"repacked={output}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Inspect, unpack, and repack IPA/TIPA archives")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_inspect = sub.add_parser("inspect")
    p_inspect.add_argument("archive", type=Path)

    p_unpack = sub.add_parser("unpack")
    p_unpack.add_argument("archive", type=Path)
    p_unpack.add_argument("output", type=Path)

    p_repack = sub.add_parser("repack")
    p_repack.add_argument("source", type=Path)
    p_repack.add_argument("output", type=Path)

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.cmd == "inspect":
        return inspect_archive(args.archive)
    if args.cmd == "unpack":
        return unpack_archive(args.archive, args.output)
    if args.cmd == "repack":
        return repack_archive(args.source, args.output)
    raise SystemExit(1)


if __name__ == "__main__":
    sys.exit(main())

