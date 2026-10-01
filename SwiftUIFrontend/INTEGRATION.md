# KayakTime SwiftUI integration

The SwiftUI frontend talks to the preserved KayakTime service at `https://38n8.dvf0.com/`.

Verified route names recovered from the original app binary:

- `api/public/init`
- `api/channel/get_list`
- `api/topic/list`
- `api/topic/vod_list`
- `api/type/get_list`
- `api/search/result`
- `api/search/suggest`
- `api/search/hot_search`
- `api/search/screen`
- `api/vod/info_new`
- user/history/favorite and feedback routes remain in the preserved original runtime.

The SwiftUI layer uses the same host and sends JSON POST requests, while keeping the original backend/runtime files untouched.
