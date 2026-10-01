# KayakTime SwiftUI integration

The SwiftUI presentation layer talks to the preserved KayakTime service rather than using placeholder cards.

## Service

Base URL:

`https://38n8.dvf0.com/`

Known application routes recovered from the original KayakTime binary include:

- `api/public/init`
- `api/public/login`
- `api/public/register`
- `api/user/info`
- `api/user/update`
- `api/channel/get_list`
- `api/channel/get_info`
- `api/topic/list`
- `api/topic/vod_list`
- `api/type/get_list`
- `api/search/result`
- `api/search/suggest`
- `api/search/hot_search`
- `api/search/screen`
- `api/vod/info_new`
- `api/user_vod/get_list`
- `api/user_vod/add`
- `api/user_vod/remove`
- `api/user_history/add`
- `api/barrage/add`
- `api/barrage/get_list`
- `api/ad/get_list`

The SwiftUI client keeps the existing Bearer-token session convention and sends cookies through `URLSession` normally. It does not replace or mock the service with local sample data.

The original application also exposes request fields such as `username`, `password`, `login_type`, `device_id`, `token`, `req_sign`, `sign`, and `cur_time`. No undocumented signing algorithm is invented here; values that already exist in the session/configuration can be forwarded without changing the backend contract.

## UI layout

The main UI uses the established full-screen pattern: the root presentation extends edge-to-edge with `.ignoresSafeArea()`, while only interactive controls use safe-area padding. The bottom navigation therefore sits over the content instead of creating the inset/black-bar appearance seen in the earlier build.
