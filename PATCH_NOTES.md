# Duplicate Swift type fix

Replace the existing `SwiftUIFrontend/Sources/Models.swift` and `HomeView.swift` with these two files.

- `Models.swift` is the single source of truth for `Category`, `MediaItem`, and `HomeViewModel`.
- `HomeView.swift` contains only `HomeView` and `RemoteImage`.
- No backend/runtime files are changed.
