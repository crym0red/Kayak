# Build

The CI workflow intentionally produces an **unsigned IPA**.

It uses:

- `xcodebuild -sdk iphoneos`
- `CODE_SIGNING_ALLOWED=NO`
- `CODE_SIGNING_REQUIRED=NO`
- `AD_HOC_CODE_SIGNING_ALLOWED=NO`

After the `.app` is built, `build.sh` creates:

`build/KayakSwiftUI-unsigned.ipa`

by packaging the app as:

`Payload/KayakSwiftUI.app`

No Apple certificate, provisioning profile, or signing secret is required for this build.

The resulting IPA is unsigned and must be signed by an appropriate tool before installation on a normal iOS device.
