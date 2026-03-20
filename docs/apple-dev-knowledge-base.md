# Apple Dev Knowledge Base

## Primary sources

- Apple Documentation: https://developer.apple.com/documentation/
- Apple Developer Community: https://developer.apple.com/community/
- Apple Open Source: https://opensource.apple.com/projects/
- Swift docs: https://developer.apple.com/documentation/swift
- Foundation Models: https://developer.apple.com/documentation/foundationmodels
- Information Property List: https://developer.apple.com/documentation/bundleresources/information-property-list

## What matters in practice

### Swift

- prefer native frameworks over hooks when building an app or helper
- keep model logic separate from UIKit or SwiftUI
- pay attention to entitlements, bundle metadata, and launch semantics

### plist workflow

- inspect and validate with `plutil`
- always keep a backup before editing
- verify value types after each edit
- prefer minimal, reversible changes

Examples:

```bash
plutil -p Info.plist
plutil -lint Info.plist
cp some.plist some.plist.bak
```

### Info.plist

High-impact keys:

- `CFBundleIdentifier`
- `CFBundleURLTypes`
- privacy usage descriptions
- extension metadata
- app groups and supported orientations

### Foundation Models

- this is Apple’s official on-device AI direction
- it does not help directly on an iPhone XS running iOS 16.3
- for older devices, app-side AI plus Vision/CoreML/OpenAI remains the practical path

