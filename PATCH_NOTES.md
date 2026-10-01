KayakTime UI/API correction

Replace only:
- SwiftUIFrontend/Sources/APIClient.swift
- SwiftUIFrontend/Sources/RootView.swift
- SwiftUIFrontend/Sources/HomeView.swift
- SwiftUIFrontend/Sources/SearchView.swift

API:
- Uses the recovered KayakTime request fields (channel_code 50009, sys_platform 30000, package_name kayaktime, app_id kayaktimea_1000, device/runtime metadata, token).
- Sends the fields in form-encoded POST first, then JSON as fallback.
- Keeps the preserved backend host and endpoint names.
- Treats the service's Chinese error envelope as an API failure instead of a JSON parsing failure.
- Does not make api/public/init a hard dependency for rendering the catalog.

UI:
- Root is edge-to-edge.
- Top safe-area inset is capped to the real modern-iPhone range so a bad/inherited inset cannot create the large black gap.
- Header is overlaid on the edge-to-edge content and its background extends behind the status area.
- Bottom navigation is a fixed-height safe-area inset with single-line labels and no wrapping.
- Scroll content reserves space for the bottom navigation.
