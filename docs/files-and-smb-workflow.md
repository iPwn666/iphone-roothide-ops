# Files and SMB Workflow

`Roothide Ops` is meant to work with the native iOS `Files` app, not with one-off transfer utilities.

## In the app

The app bootstraps these folders in its `Documents` directory:

- `Imports`
- `Exports`
- `Logs`
- `Scripts`

With `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` enabled, these folders are intended to stay visible in `Files`.

## On the host

This Linux host exposes a Samba share named `iPhoneDrop`.

Paths inside the share:

- `Inbox`
- `FromiPhone`
- `Archives`

Current host addresses:

- LAN: `smb://192.168.50.42`
- WireGuard: `smb://10.77.0.1`

## iPhone steps

1. Open `Files`.
2. Tap the `...` menu.
3. Choose `Connect to Server`.
4. Enter `smb://192.168.50.42` on local Wi-Fi.
5. If WireGuard is active, `smb://10.77.0.1` can be used as a fallback.
6. Open the `iPhoneDrop` share.

## Recommended flow

- Copy host-to-phone inputs into `Inbox`.
- Move them into `Roothide Ops/Imports` on the phone.
- Export logs or archives from the app into `Exports`.
- Move finished outputs back to `iPhoneDrop/FromiPhone`.
