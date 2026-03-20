#!/usr/bin/env python3
from pathlib import Path
import os
import sys


def main() -> int:
    key = os.environ.get("SSH_PUBLIC_KEY", "").strip()
    if not key:
        print("Set SSH_PUBLIC_KEY in the environment.")
        return 1

    target = Path.home() / ".ssh" / "authorized_keys"
    target.parent.mkdir(parents=True, exist_ok=True)
    existing = target.read_text(encoding="utf-8", errors="ignore") if target.exists() else ""
    if key not in existing:
        with target.open("a", encoding="utf-8") as handle:
            if existing and not existing.endswith("\n"):
                handle.write("\n")
            handle.write(key + "\n")
    try:
        os.chmod(target.parent, 0o700)
        os.chmod(target, 0o600)
    except OSError:
        pass
    print(f"authorized_keys updated: {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

