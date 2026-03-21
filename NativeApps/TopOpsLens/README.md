# TopOps Lens

Native Swift iPhone camera app inspired by the speed-first ShadowLens workflow:

- tap shutter for stills
- hold shutter to record clips
- double tap preview to flip cameras
- tap to focus and expose
- pinch to zoom
- drag on the preview to bias exposure
- aesthetic look presets for still captures
- aspect guide overlays for 9:16, 4:5 and 1:1 framing
- automatic save to Photos when allowed, otherwise to `Documents/Captures`

## Build

```bash
cd NativeApps/TopOpsLens
xcodegen generate
xcodebuild \
  -project TopOpsLens.xcodeproj \
  -scheme TopOpsLens \
  -configuration Release \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Install

```bash
python3 scripts/install_topopslens_on_phone.py --host 10.77.0.2
```
