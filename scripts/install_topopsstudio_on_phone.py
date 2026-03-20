#!/usr/bin/env python3

from __future__ import annotations

import argparse
import glob
import os
import shlex
import subprocess
import sys
from pathlib import Path


DEFAULT_ARTIFACT_PATTERNS = [
	"~/Stazene/topopsstudio-*/TopOpsStudio.tipa",
	"~/Stazene/topopsstudio-*/TopOpsStudio-unsigned.ipa",
	"~/Stažené/topopsstudio-*/TopOpsStudio.tipa",
	"~/Stažené/topopsstudio-*/TopOpsStudio-unsigned.ipa",
]
REMOTE_INSTALL_DIR = "/var/jb/var/mobile/Documents/InstallQueue"
REMOTE_INSTALL_FILE = f"{REMOTE_INSTALL_DIR}/TopOpsStudio.tipa"


def latest_match(patterns: list[str]) -> Path:
	matches: list[Path] = []
	for pattern in patterns:
		matches.extend(Path(path).expanduser() for path in glob.glob(os.path.expanduser(pattern)))
	if not matches:
		raise FileNotFoundError(f"No files matched {patterns!r}.")
	return max(matches, key=lambda path: path.stat().st_mtime)


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
	return subprocess.run(command, check=True, capture_output=True, text=True)


def remote_shell(command: str) -> str:
	return f"zsh -lc {shlex.quote(command)}"


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(description="Upload and install TopOps Studio with TrollStore helper.")
	parser.add_argument("--host", default="10.77.0.2")
	parser.add_argument("--user", default="root")
	parser.add_argument("--port", type=int, default=22)
	parser.add_argument("--artifact", default=None, help="Local IPA/TIPA path or glob.")
	return parser.parse_args()


def main() -> int:
	args = parse_args()
	if args.artifact:
		artifact_arg = os.path.expanduser(args.artifact)
		if any(ch in artifact_arg for ch in "*?[]"):
			artifact = latest_match([artifact_arg])
		else:
			artifact = Path(artifact_arg)
	else:
		artifact = latest_match(DEFAULT_ARTIFACT_PATTERNS)

	if not artifact.is_file():
		raise FileNotFoundError(f"Artifact not found: {artifact}")

	ssh_base = [
		"ssh",
		"-o",
		"UserKnownHostsFile=/dev/null",
		"-o",
		"StrictHostKeyChecking=no",
		"-p",
		str(args.port),
		f"{args.user}@{args.host}",
	]
	scp_base = [
		"scp",
		"-o",
		"UserKnownHostsFile=/dev/null",
		"-o",
		"StrictHostKeyChecking=no",
		"-P",
		str(args.port),
	]

	run(ssh_base + [remote_shell(f"mkdir -p {shlex.quote(REMOTE_INSTALL_DIR)}")])
	subprocess.run(scp_base + [str(artifact), f"{args.user}@{args.host}:{REMOTE_INSTALL_FILE}"], check=True)

	helper_find = run(
		ssh_base + [remote_shell("find /var/containers/Bundle/Application -path '*/TrollStore.app/trollstorehelper' | head -n 1")]
	)
	helper_path = helper_find.stdout.strip()
	if not helper_path:
		raise RuntimeError("TrollStore helper not found on phone.")

	install_command = f"{shlex.quote(helper_path)} install skip-uicache force {shlex.quote(REMOTE_INSTALL_FILE)}"
	install_result = subprocess.run(
		ssh_base + [remote_shell(install_command)],
		check=False,
		capture_output=True,
		text=True,
	)
	if install_result.returncode != 0:
		sys.stderr.write(install_result.stdout)
		sys.stderr.write(install_result.stderr)
		raise RuntimeError("TopOps Studio installation failed through TrollStore helper.")

	print(f"artifact={artifact}")
	print(f"remote={REMOTE_INSTALL_FILE}")
	print(f"helper={helper_path}")
	print("mode=trollstorehelper")
	return 0


if __name__ == "__main__":
	sys.exit(main())
