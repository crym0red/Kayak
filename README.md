# KayakTime SwiftUI Frontend Rebuild

This package preserves the supplied KayakTime application bundle under `OriginalApp/` and places the new SwiftUI frontend scaffold under `SwiftUIFrontend/`.

The original bundle remains the source of truth for existing backend/configuration/framework resources. The SwiftUI layer is intentionally separated so those components are not silently discarded.

Before redistribution, verify that you have rights to reuse the original application, frameworks, APIs, content, and embedded components.

## GitHub packaging

The original backend executable is preserved byte-for-byte, but is split into 20 MiB chunks so each repository file remains comfortably below GitHub's single-file limits. Run `./Scripts/restore-backend.sh` to reconstruct `OriginalApp/KayakTime.app/KayakTime`; the script verifies the SHA-256 checksum before returning success.

The existing framework bundle and required runtime dylibs/resources are retained. Generated build output is not committed.
