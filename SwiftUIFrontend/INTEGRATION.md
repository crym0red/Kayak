# Integration plan

1. Keep the original `OriginalApp/Payload/...app` bundle and its framework/resource inventory as the reference.
2. Do not remove embedded frameworks/dylibs merely because SwiftUI replaces the visible UI.
3. Migrate only the presentation layer after each backend/framework dependency has a native integration point.
4. Reuse the existing API host/configuration and verified request/response contract.
5. Verify authentication against the authorized service before replacing the original authentication flow.
6. Build/sign the final app only after the original bundle identifier, entitlements, embedded-framework signatures, and load paths have been reconciled.

This scaffold intentionally does not claim that a raw copied .app can be converted into a valid Xcode project by zipping it; Xcode project metadata, source-level linkage, signing, and target membership still need to be constructed explicitly.
