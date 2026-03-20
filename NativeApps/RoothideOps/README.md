# Roothide Ops

Nativni SwiftUI companion app pro repo `iphone-roothide-ops`.

## Focus

- iPhone-first prehled nad stavem zarizeni
- offline-friendly prochazeni dokumentace
- rychla recovery reference primo v telefonu
- inventar helperu pro phone i host workflow
- GitHub Actions build do `.ipa` i `.tipa`

## Build

App pouziva `XcodeGen`.

```bash
cd NativeApps/RoothideOps
xcodegen generate
xcodebuild \
  -project RoothideOps.xcodeproj \
  -scheme RoothideOps \
  -configuration Release \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Install

Po CI buildu lze artifact nainstalovat do telefonu pres:

```bash
python3 scripts/install_native_app_on_phone.py --host 10.77.0.2
```
