# iPhone Roothide Ops

Operational docs, audits, and helper scripts for a roothide-jailbroken iPhone XS on iOS 16.3.

## Scope

- roothide/Sileo/ElleKit maintenance
- APT source cleanup and package-manager recovery
- SSH, USB, and WireGuard remote access
- Pythonista and eSign helper workflows
- IPA/TIPA inspection and repacking

## Current state

- package-manager parser issues fixed
- `apt-get update` clean with the curated source set
- broken `dpkg` symlink chain repaired
- high-risk tweak injection reduced to a smaller active set
- `com.roothide.manager` upgraded to `1.3.9`

## Layout

- `docs/`: audits, workflows, and reference notes
- `scripts/`: generic recovery and device helper scripts
- `tools/`: standalone utilities
- `templates/`: reusable config and shell templates

## Notes

- This repo intentionally avoids publishing device-specific secrets.
- Replace placeholders before using any template on a live device.
- Keep a local backup of every plist or source file before editing it on-device.
