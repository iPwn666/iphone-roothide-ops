# Remote Access

## Preferred order

1. WireGuard + SSH
2. USB forwarding + SSH
3. on-device NewTerm or Pythonista recovery

## SSH expectations

- `root` is best for maintenance tasks
- `mobile` is safer for normal user-space operations
- keep public-key auth available for both accounts when possible

## WireGuard

Use WireGuard as the main fallback when USB disappears.

Recommended properties:

- persistent keepalive on the phone peer
- a stable server-side endpoint
- a dedicated SSH alias for the tunnel address

## USB

USB is best for:

- device recovery when Wi-Fi or WG is gone
- low-latency installs and file copies
- accessibility or lockdown-based tooling

## Recovery path

If remote access breaks after a respring or userspace restart:

1. re-enable the WireGuard tunnel on the phone
2. verify SSH launchd state
3. restore `authorized_keys` if roothide or account state changed
4. only then touch APT or tweak state again

