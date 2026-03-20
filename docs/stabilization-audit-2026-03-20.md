# Stabilization Audit - 2026-03-20

## Device baseline

- Model: iPhone XS (`iPhone11,2`)
- OS: iOS `16.3` (`20D47`)
- Jailbreak stack: roothide + Sileo + ElleKit

## Fixed

- removed the hard APT parser failure caused by a broken legacy repo
- reduced the active source set to a clean, updateable minimum
- repaired the `dpkg` execution path so package operations work again
- upgraded `com.roothide.manager` from `1.3.8` to `1.3.9`
- restored SSH access for both `root` and `mobile`

## Active tweak inject set

- `AAASnowBoardStub`
- `AppData`
- `CCSupport`
- `CepheiSpringBoard`
- `Cylinder`
- `Erika`
- `GoodWiFi`
- `PreferenceLoader`
- `RebootHelper`
- `SandyProxy`
- `Snowboard`
- `afc2dService`
- `mrybootstrap`
- `opa334`

## Quarantined tweak inject set

- `3DAppVersionSpoofer`
- `AppTool`
- `ArtFull`
- `EeveeSpotify`
- `FLEXing`
- `Flex`
- `NewTab`
- `ReScale`
- `ReScaleActivator`
- `ReScaleKB`
- `ReScaleUIKit`
- `Satella`
- `iOSSecuritySuiteBypass`
- `libFLEX`

## Result

- package manager is usable again
- package warnings from noisy third-party repos are gone with the minimal source set
- the active tweak profile now favors stability over broad debug and bypass injection

