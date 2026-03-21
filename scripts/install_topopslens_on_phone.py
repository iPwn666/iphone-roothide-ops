#!/usr/bin/env python3

from __future__ import annotations

import argparse
import glob
import os
import plistlib
import shlex
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path


DEFAULT_ARTIFACT_PATTERNS = [
	"~/Stazene/topopslens-*/TopOpsLens-build/TopOpsLens.tipa",
	"~/Stazene/topopslens-*/TopOpsLens-build/TopOpsLens-unsigned.ipa",
	"~/Stazene/topopslens-*/TopOpsLens.tipa",
	"~/Stazene/topopslens-*/TopOpsLens-unsigned.ipa",
	"~/Stažené/topopslens-*/TopOpsLens-build/TopOpsLens.tipa",
	"~/Stažené/topopslens-*/TopOpsLens-build/TopOpsLens-unsigned.ipa",
	"~/Stažené/topopslens-*/TopOpsLens.tipa",
	"~/Stažené/topopslens-*/TopOpsLens-unsigned.ipa",
]
REMOTE_INSTALL_DIR = "/var/mobile/Documents/InstallQueue"
REMOTE_INSTALL_FILE = f"{REMOTE_INSTALL_DIR}/TopOpsLens.tipa"
REMOTE_JB_APPS_DIR = "/var/jb/Applications"


def latest_match(patterns: list[str]) -> Path:
	matches: list[Path] = []
	for pattern in patterns:
		matches.extend(Path(path).expanduser() for path in glob.glob(os.path.expanduser(pattern)))
	if not matches:
		raise FileNotFoundError(f"No files matched {patterns!r}.")
	return max(matches, key=lambda path: path.stat().st_mtime)


def run(command: list[str]) -> None:
	subprocess.run(command, check=True)


def run_capture(command: list[str]) -> subprocess.CompletedProcess[str]:
	return subprocess.run(command, check=False, capture_output=True, text=True)


def remote_shell(command: str) -> str:
	return f"zsh -lc {shlex.quote(command)}"


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(description="Upload and install TopOpsLens on the phone.")
	parser.add_argument("--host", default="10.77.0.2")
	parser.add_argument("--user", default="root")
	parser.add_argument("--port", type=int, default=22)
	parser.add_argument("--artifact", default=None, help="Local IPA/TIPA path or glob.")
	return parser.parse_args()


def extract_app_bundle(artifact: Path) -> tuple[tempfile.TemporaryDirectory[str], Path, str]:
	tempdir = tempfile.TemporaryDirectory(prefix="topopslens-install-")
	root = Path(tempdir.name)
	with zipfile.ZipFile(artifact) as archive:
		archive.extractall(root)
	payload = root / "Payload"
	apps = sorted(payload.glob("*.app"))
	if not apps:
		tempdir.cleanup()
		raise RuntimeError(f"No .app bundle found inside {artifact}.")
	info_plist = apps[0] / "Info.plist"
	with info_plist.open("rb") as handle:
		info = plistlib.load(handle)
	executable = info.get("CFBundleExecutable")
	if not executable:
		tempdir.cleanup()
		raise RuntimeError(f"Missing CFBundleExecutable in {info_plist}.")
	return tempdir, apps[0], executable


def install_via_jailbreak_fallback(
	artifact: Path,
	ssh_base: list[str],
	scp_base: list[str],
	bundle_id: str,
) -> None:
	tempdir, app_bundle, executable_name = extract_app_bundle(artifact)
	remote_app = f"{REMOTE_JB_APPS_DIR}/{app_bundle.name}"
	remote_executable = f"{remote_app}/{executable_name}"
	try:
		run(ssh_base + [remote_shell(f"mkdir -p {shlex.quote(REMOTE_JB_APPS_DIR)}")])
		run(ssh_base + [remote_shell(f"rm -rf {shlex.quote(remote_app)}")])
		run(scp_base + ["-r", str(app_bundle), f"{ssh_base[-1]}:{REMOTE_JB_APPS_DIR}/"])
		run(
			ssh_base
			+ [
				remote_shell(
					" && ".join(
						[
							f"find {shlex.quote(remote_app)} -type d -exec chmod 755 {{}} +",
							f"find {shlex.quote(remote_app)} -type f -exec chmod 644 {{}} +",
							f"chmod 755 {shlex.quote(remote_executable)}",
							f"uicache -p {shlex.quote(remote_app)}",
							f"uiopen --bundleid {shlex.quote(bundle_id)} || true",
							"sbreload >/dev/null 2>&1 || true",
						]
					)
				)
			]
		)
	finally:
		tempdir.cleanup()


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
		"-F",
		"/dev/null",
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
		"-F",
		"/dev/null",
		"-o",
		"UserKnownHostsFile=/dev/null",
		"-o",
		"StrictHostKeyChecking=no",
		"-P",
		str(args.port),
	]

	run(ssh_base + [remote_shell(f"mkdir -p {shlex.quote(REMOTE_INSTALL_DIR)}")])
	run(scp_base + [str(artifact), f"{args.user}@{args.host}:{REMOTE_INSTALL_FILE}"])

	helper_find = subprocess.run(
		ssh_base + [remote_shell("find /var/containers/Bundle/Application -path '*/TrollStore.app/trollstorehelper' | head -n 1")],
		check=True,
		capture_output=True,
		text=True,
	)
	helper_path = helper_find.stdout.strip()
	if not helper_path:
		raise RuntimeError("TrollStore helper not found on phone.")

	install_command = f"{shlex.quote(helper_path)} install skip-uicache force {shlex.quote(REMOTE_INSTALL_FILE)}"
	install_result = run_capture(ssh_base + [remote_shell(install_command)])
	if install_result.returncode != 0:
		sys.stderr.write(install_result.stdout)
		sys.stderr.write(install_result.stderr)
		install_via_jailbreak_fallback(
			artifact=artifact,
			ssh_base=ssh_base,
			scp_base=scp_base,
			bundle_id="com.topwnz.TopOpsLens",
		)
		mode = "jailbreak-fallback"
	else:
		mode = "trollstorehelper"

	print(f"artifact={artifact}")
	print(f"remote={REMOTE_INSTALL_FILE}")
	print(f"helper={helper_path}")
	print(f"mode={mode}")
	return 0


if __name__ == "__main__":
	sys.exit(main())
