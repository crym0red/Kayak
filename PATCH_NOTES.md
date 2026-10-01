Swift 6 concurrency fix

Replaced the three `async let` API calls in Models.swift with sequential awaits.
The API client currently returns the legacy `[String: Any]` response type, which is
not Sendable. Using async let attempts to transfer that value across concurrency
boundaries and fails under strict concurrency checking. Sequential awaits keep the
response on the MainActor while preserving the existing API contract and backend.

Only this source file needs replacement.
