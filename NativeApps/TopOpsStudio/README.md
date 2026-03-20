# TopOps Studio

Native Swift iPhone workbench for:

- Files-first workspace in `Documents`
- on-device text editing for Swift, Python, shell, plist and markdown
- workspace file browser with local plist inspector/editor
- importing Pythonista JSON/TXT reports from Files or SMB
- Vision OCR from screenshots
- Core ML model inventory from the `Models` folder

## Build

```bash
cd NativeApps/TopOpsStudio
xcodegen generate
xcodebuild \
  -project TopOpsStudio.xcodeproj \
  -scheme TopOpsStudio \
  -configuration Release \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Install

After CI builds a `.tipa`, install it with:

```bash
python3 scripts/install_topopsstudio_on_phone.py --host 10.77.0.2
```
