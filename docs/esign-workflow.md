# eSign Workflow

eSign is useful as a phone-side GUI layer over IPA/TIPA handling.

## Good use cases

- import repositories and download IPA/TIPA files
- inspect archive contents
- hand app bundles off to TrollStore
- do quick bundle-level checks after unpacking

## Safe workflow

1. only work with apps you own or are allowed to modify
2. keep a pristine copy of the original IPA/TIPA
3. inspect `Payload/*.app/Info.plist`
4. inspect extensions and embedded frameworks
5. repack and validate the archive structure before install

## When not to rely on eSign

- larger refactors
- daemon or helper development
- repeatable multi-step patching
- anything that should be versioned and reviewed

For those cases, use source control, reproducible builds, and scripted installs.

