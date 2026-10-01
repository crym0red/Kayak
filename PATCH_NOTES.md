# KayakTime UI/API format + full-screen safe-area patch

Replace the matching files in the existing repository.

Changes:
- API client tolerates JSON envelopes and JSON encoded as strings.
- Retries legacy form-encoded POST bodies.
- Preserves the existing API host and endpoints.
- Expands common `data/result/list/vod_list/topic_list/...` response containers.
- Home/search no longer rely on a single Codable JSON shape.
- RootView is edge-to-edge using the proven Fugacious full-screen pattern.
- The background and primary content extend through the Dynamic Island/status-bar and Home Indicator areas.
- Safe-area handling is applied only where interactive controls need it.
- Bottom navigation remains above the Home Indicator via `safeAreaInset`.
- Removed the fixed bottom content padding that was creating the oversized lower gap.
- Search header uses the device's actual top safe-area inset rather than a fixed offset.
- No backend/runtime files are changed.
