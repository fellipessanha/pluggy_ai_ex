# Pluggy AI Elixir Library - Design Document

**Project**: `~/repos/pluggy_ai_ex` | package: `pluggy_ai` | module prefix: `Pluggy`

---

## 1. Project Structure

```
pluggy_ai_ex/
├── mix.exs                            # req required; kino, phoenix_live_view optional
├── lib/
│   ├── pluggy.ex                      # Top-level module, base_url/0
│   ├── pluggy/
│   │   ├── error.ex                   # %Pluggy.Error{code, message, code_description, data}
│   │   ├── key_transform.ex           # camelCase <-> snake_case (to_snake/1, to_camel/1)
│   │   ├── auth.ex                    # Req plugin: attaches X-API-KEY, retries on 401
│   │   ├── client.ex                  # %Pluggy.Client{req, client_id, client_secret}
│   │   ├── http.ex                    # Internal get/post/patch/delete + error wrapping
│   │   ├── session.ex                 # Struct + functional API: holds client, connect_token, item
│   │   ├── connectors.ex             # list/1, get/2, validate/3
│   │   ├── items.ex                   # create/2, get/2, update/3, delete/2, send_mfa/3, disable_auto_sync/2
│   │   ├── consents.ex               # list/2, get/2
│   │   ├── accounts.ex               # list/2-3, get/2, statements/2
│   │   ├── transactions.ex           # list/2-3, get/2, update/3
│   │   ├── investments.ex            # list/2-3, get/2, transactions/2-3
│   │   ├── identity.ex               # list/2, get/2
│   │   ├── webhooks.ex               # list/1, create/2, get/2, update/3, delete/2
│   │   ├── categories.ex             # list/1-2, get/2, list_rules/1, create_rule/2
│   │   ├── loans.ex                  # list/2, get/2
│   │   ├── merchants.ex              # list/1-2
│   │   ├── bills.ex                  # list/2, get/2
│   │   ├── payments/
│   │   │   ├── customers.ex          # CRUD (list, create, get, update, delete)
│   │   │   ├── recipients.ex         # CRUD
│   │   │   ├── institutions.ex       # list/1-2, get/2
│   │   │   ├── requests.ex           # CRUD + create_pix_qr/2
│   │   │   ├── schedules.ex          # list/2, cancel_all/2, cancel/3
│   │   │   ├── automatic_pix.ex      # create, schedule, list/get/cancel schedules, retry
│   │   │   └── intents.ex            # create/2, list/2, get/2
│   │   ├── smart_transfers/
│   │   │   ├── preauthorizations.ex  # list/1-2, create/2, get/2
│   │   │   └── payments.ex           # create/2, get/2
│   │   ├── boletos/
│   │   │   ├── connections.ex        # create/2, create_from_item/2
│   │   │   └── boletos.ex            # create/2, get/2, cancel/2
│   │   └── connect/
│   │       ├── kino.ex               # Kino.JS.Live widget (optional dep guard)
│   │       └── live.ex               # Phoenix LiveComponent (optional dep guard)
├── priv/static/
│   └── pluggy_connect_hook.js         # JS hook export for Phoenix apps
└── test/
    ├── test_helper.exs
    ├── support/
    │   ├── fixtures.ex                # Sample API responses as maps
    │   └── mock_plug.ex               # Plug-based mock server (Req plug: option)
    └── pluggy/                        # Mirrors lib/ structure, one test file per module
```

---

## 2. Core Modules

### 2.1 `Pluggy` (lib/pluggy.ex)

Top-level facade module. Provides `base_url/0` returning envionment specified api url, or the default `"https://api.pluggy.ai"`.

### 2.2 `Pluggy.Error` (lib/pluggy/error.ex)

```elixir
defstruct [:code, :message, :code_description, :data]

# From API response (already snake_cased by pipeline):
Error.from_response(%{code: 401, message: "Unauthorized"})

# From transport errors:
Error.transport(:timeout)
```

### 2.3 `Pluggy.KeyTransform` (lib/pluggy/key_transform.ex)

Internal module (`@moduledoc false`). Two public functions:

```elixir
# Response: camelCase string keys -> snake_case atoms (recursive)
KeyTransform.to_snake(%{"itemId" => "abc", "paymentData" => %{"refNumber" => 1}})
# => %{item_id: "abc", payment_data: %{ref_number: 1}}

# Request: snake_case atom keys -> camelCase strings (recursive)
KeyTransform.to_camel(%{item_id: "abc", payment_data: %{ref_number: 1}})
# => %{"itemId" => "abc", "paymentData" => %{"refNumber" => 1}}
```

Uses `Macro.underscore/1` for camel->snake. Manual split+capitalize for snake->camel.
`String.to_atom/1` is safe: bounded key set from OAS spec (~300 unique keys).

Also exposes `to_camel_string/1` (public but `@doc false`) for use by `Pluggy.HTTP` query param conversion.

### 2.4 `Pluggy.Auth` (lib/pluggy/auth.ex)

Req plugin. Attaches two steps to a `Req.Request`:

**Request step (`pluggy_auth`)**:
- If no API key cached in `req.options[:pluggy_api_key]`, calls `POST /auth` eagerly
- Attaches `x-api-key` header

**Response step (`pluggy_retry_auth`)**:
- On 401, re-authenticates via `POST /auth`, updates the key, replays the request once
- Tracks `:pluggy_auth_retried` flag to prevent infinite loops
- Auth call uses a fresh minimal `Req.Request` (no auth plugin) to avoid recursion

```elixir
Pluggy.Auth.attach(req, client_id, client_secret)
```

Registers custom options: `:pluggy_client_id`, `:pluggy_client_secret`, `:pluggy_api_key`, `:pluggy_auth_retried`.

### 2.5 `Pluggy.Client` (lib/pluggy/client.ex)

```elixir
@type t :: %Pluggy.Client{
  req: Req.Request.t(),
  client_id: String.t(),
  client_secret: String.t()
}

# Creation
{:ok, client} = Pluggy.Client.new("client_id", "client_secret")
client = Pluggy.Client.new!("client_id", "client_secret")

# Options
Pluggy.Client.new("id", "secret", base_url: "https://custom.api.url", req_options: [timeout: 30_000])

# Connect token (convenience, also available on Session)
{:ok, token} = Pluggy.Client.connect_token(client)
{:ok, token} = Pluggy.Client.connect_token(client, item_id: "abc")
```

Assembles the Req pipeline:
1. `Req.new(base_url: ..., headers: [accept: "application/json"])` + any user `req_options`
2. Attaches `Pluggy.Auth` plugin
3. Appends response step `pluggy_snake_keys` (after Req's `decode_body`)
4. Prepends request step `pluggy_camel_body` (before Req's `encode_body`)

**Step ordering** (critical):
- Request: `[pluggy_camel_body, pluggy_auth, ...(req built-in)..., encode_body]`
- Response: `[decode_body, ...(req built-in)..., pluggy_retry_auth, pluggy_snake_keys]`

Use `prepend_request_steps` for camel body + auth. Use `append_response_steps` for snake keys.

### 2.6 `Pluggy.HTTP` (lib/pluggy/http.ex)

Internal module (`@moduledoc false`). Centralizes HTTP calls and error handling:

```elixir
HTTP.get(client, "/accounts", params: [item_id: "abc", page_size: 20])
HTTP.post(client, "/items", json: %{connector_id: 200})
HTTP.patch(client, "/items/abc", json: %{webhook_url: "https://..."})
HTTP.delete(client, "/items/abc")
HTTP.unwrap!({:ok, result})  # => result
HTTP.unwrap!({:error, err})  # => raises
```

- Converts query params from snake_case to camelCase before passing to Req
- Returns `{:ok, body}` for 2xx, `{:error, %Pluggy.Error{}}` for error responses
- Returns `{:error, %Pluggy.Error{code: :transport}}` for connection errors

---

## 3. Resource Modules

All follow the same pattern: stateless functions, `%Pluggy.Client{}` as first arg, delegate to `Pluggy.HTTP`.

### Pattern

```elixir
defmodule Pluggy.SomeResource do
  alias Pluggy.{Client, HTTP}

  def list(%Client{} = client, required_param, opts \\ []) do
    HTTP.get(client, "/resource", params: [requiredParam: required_param] ++ opts)
  end
  def list!(client, required_param, opts \\ []), do: HTTP.unwrap!(list(client, required_param, opts))

  def get(%Client{} = client, id), do: HTTP.get(client, "/resource/#{id}")
  def get!(client, id), do: HTTP.unwrap!(get(client, id))

  def create(%Client{} = client, attrs), do: HTTP.post(client, "/resource", json: attrs)
  def create!(client, attrs), do: HTTP.unwrap!(create(client, attrs))
end
```

### Complete Resource API

| Module | Functions | Endpoints |
|--------|-----------|-----------|
| `Pluggy.Connectors` | `list/1-2`, `get/2-3`, `validate/3` | GET /connectors, GET /connectors/{id}, POST /connectors/{id}/validate |
| `Pluggy.Items` | `create/2`, `get/2`, `update/3`, `delete/2`, `send_mfa/3`, `disable_auto_sync/2` | POST/GET/PATCH/DELETE /items/{id}, POST /items/{id}/mfa, PATCH /items/{id}/disable-auto-sync |
| `Pluggy.Consents` | `list/2`, `get/2` | GET /consents?itemId=, GET /consents/{id} |
| `Pluggy.Accounts` | `list/2-3`, `get/2`, `statements/2` | GET /accounts?itemId=, GET /accounts/{id}, GET /accounts/{id}/statements |
| `Pluggy.Transactions` | `list/2-3`, `get/2`, `update/3` | GET /transactions?accountId=, GET /transactions/{id}, PATCH /transactions/{id} |
| `Pluggy.Investments` | `list/2-3`, `get/2`, `transactions/2-3` | GET /investments?itemId=, GET /investments/{id}, GET /investments/{id}/transactions |
| `Pluggy.Identity` | `list/2`, `get/2` | GET /identity?itemId=, GET /identity/{id} |
| `Pluggy.Webhooks` | `list/1`, `create/2`, `get/2`, `update/3`, `delete/2` | Full CRUD on /webhooks |
| `Pluggy.Categories` | `list/1-2`, `get/2`, `list_rules/1`, `create_rule/2` | GET /categories, GET /categories/{id}, GET/POST /categories/rules |
| `Pluggy.Loans` | `list/2`, `get/2` | GET /loans?itemId=, GET /loans/{id} |
| `Pluggy.Merchants` | `list/1-2` | GET /merchants?cnpjs= |
| `Pluggy.Bills` | `list/2`, `get/2` | GET /bills?accountId=, GET /bills/{id} |
| `Pluggy.Payments.Customers` | CRUD | /payments/customers |
| `Pluggy.Payments.Recipients` | CRUD | /payments/recipients |
| `Pluggy.Payments.Institutions` | `list/1-2`, `get/2` | /payments/recipients/institutions |
| `Pluggy.Payments.Requests` | CRUD + `create_pix_qr/2` | /payments/requests, /payments/requests/pix-qr |
| `Pluggy.Payments.Schedules` | `list/2`, `cancel_all/2`, `cancel/3` | /payments/requests/{id}/schedules |
| `Pluggy.Payments.AutomaticPix` | `create/2`, `schedule/3`, `list_schedules/2`, `get_schedule/3`, `cancel/2`, `cancel_schedule/3`, `retry_schedule/4` | /payments/requests/automatic-pix/* |
| `Pluggy.Payments.Intents` | `create/2`, `list/2`, `get/2` | /payments/intents |
| `Pluggy.SmartTransfers.Preauthorizations` | `list/1-2`, `create/2`, `get/2` | /smart-transfers/preauthorizations |
| `Pluggy.SmartTransfers.Payments` | `create/2`, `get/2` | /smart-transfers/payments |
| `Pluggy.Boletos.Connections` | `create/2`, `create_from_item/2` | /boleto-connections, /boleto-connections/from-item |
| `Pluggy.Boletos` | `create/2`, `get/2`, `cancel/2` | /boletos, /boletos/{id}/cancel |

---

## 4. Session (`Pluggy.Session`)

A plain struct with functional API. No GenServer — state lives in the caller's process (LiveView socket, Livebook cell, etc.).

### Design Rationale

**Why not a GenServer?**

Both target environments already provide process contexts that naturally hold state:

- **Phoenix LiveView**: Each user's LiveView is an isolated process. State belongs in `socket.assigns`. Adding a separate GenServer per session means extra processes, message passing overhead, and coordination complexity.
- **Livebook**: Cells execute sequentially in the same process. State flows naturally through variables. A GenServer adds indirection without benefit.

The Session only holds **passive data** (client, token, item) — no background work, timers, or subscriptions. A struct with functional transformations is simpler, more composable, and idiomatic for both environments.

### Struct Definition

```elixir
defmodule Pluggy.Session do
  defstruct [:client, :connect_token, :item, :item_id, connect_token_opts: []]

  @type t :: %__MODULE__{
    client: Pluggy.Client.t(),
    connect_token: String.t() | nil,
    item: map() | nil,
    item_id: String.t() | nil,
    connect_token_opts: keyword()
  }
end
```

### API

```elixir
# Create a new session
session = Pluggy.Session.new(client)
session = Pluggy.Session.new(client, webhook_url: "https://...")

# Connect token (fetches if not cached, returns updated session)
{:ok, token, session} = Pluggy.Session.connect_token(session)

# Set item after widget connection (returns new session)
session = Pluggy.Session.with_item(session, item_data)

# Access item data
item = session.item
item_id = session.item_id

# Convenience resource accessors (delegates to resource modules)
{:ok, accounts} = Pluggy.Session.accounts(session)
{:ok, txns} = Pluggy.Session.transactions(session, account_id)
{:ok, investments} = Pluggy.Session.investments(session)
{:ok, identity} = Pluggy.Session.identity(session)
{:ok, loans} = Pluggy.Session.loans(session)

# Get raw client for direct API calls
client = session.client
```

Returns `{:error, :no_item}` for resource calls when no item has been set yet.

### Usage Examples

**Phoenix LiveView:**
```elixir
def mount(_params, _session, socket) do
  {:ok, client} = Pluggy.Client.new("id", "secret")
  session = Pluggy.Session.new(client)
  {:ok, token, session} = Pluggy.Session.connect_token(session)
  {:ok, assign(socket, session: session, connect_token: token)}
end

def handle_event("pluggy:connected", item_data, socket) do
  session = Pluggy.Session.with_item(socket.assigns.session, item_data)
  {:noreply, assign(socket, session: session)}
end

def handle_event("load_accounts", _, socket) do
  {:ok, accounts} = Pluggy.Session.accounts(socket.assigns.session)
  {:noreply, assign(socket, accounts: accounts)}
end
```

**Livebook:**
```elixir
# Cell 1: Setup
{:ok, client} = Pluggy.Client.new(client_id, client_secret)
session = Pluggy.Session.new(client)

# Cell 2: Get token for widget
{:ok, token, session} = Pluggy.Session.connect_token(session)
Pluggy.Connect.Kino.new(token: token)  # renders widget

# Cell 3: After user connects (widget returns item)
session = Pluggy.Session.with_item(session, item)

# Cell 4: Fetch data
{:ok, accounts} = Pluggy.Session.accounts(session)
{:ok, transactions} = Pluggy.Session.transactions(session, hd(accounts)["id"])
```

---

## 5. Connect Widgets

### 5.1 `Pluggy.Connect.Kino` (lib/pluggy/connect/kino.ex)

Guarded: `if Code.ensure_loaded?(Kino.JS.Live) do ... end`

Kino.JS.Live widget that renders Pluggy Connect and returns the connected item.

```elixir
# Usage in Livebook
{:ok, token, session} = Pluggy.Session.connect_token(session)
widget = Pluggy.Connect.Kino.new(token: token, include_sandbox: true)

# Widget is interactive - user completes bank connection
# After completion, get the item from the widget:
item = Kino.render(widget) |> Pluggy.Connect.Kino.await_item()

# Update session with item
session = Pluggy.Session.with_item(session, item)
```

**Implementation:**
- `init/2`: stores token and options
- `handle_connect/1`: sends `%{token, include_sandbox}` to JS
- `handle_event("connection_success", item_data, ctx)`: stores item, makes it available via `await_item/1`
- JS: loads Pluggy Connect SDK from CDN, renders widget, pushes events

### 5.2 `Pluggy.Connect.Live` (lib/pluggy/connect/live.ex)

Guarded: `if Code.ensure_loaded?(Phoenix.LiveView) do ... end`

Phoenix LiveComponent. Requires a JS hook (`PluggyConnect`) registered in the app.

```elixir
# In LiveView template:
<.live_component module={Pluggy.Connect.Live} id="pluggy" connect_token={@connect_token} include_sandbox={true} />

# Handle the connection event in your LiveView:
def handle_event("pluggy:connected", item_data, socket) do
  session = Pluggy.Session.with_item(socket.assigns.session, item_data)
  {:noreply, assign(socket, session: session)}
end
```

JS hook provided at `priv/static/pluggy_connect_hook.js` with `createPluggyConnectHook()` export.

---

## 6. Testing Strategy

- **No external HTTP**: Use Req's `plug:` option to route all requests to `Pluggy.Test.MockPlug`
- **MockPlug**: Pattern-matches on method + path, returns fixture data from `Pluggy.Test.Fixtures`
- **Test setup**: `Pluggy.Client.new("id", "secret", req_options: [plug: MockPlug])`
- **Fixtures**: Sample responses matching real API shapes (from OAS spec)

---

## 7. Implementation Order

1. Foundation: `mix.exs`, `pluggy.ex`, `error.ex`, `key_transform.ex` + tests
2. Auth & Client: `auth.ex`, `client.ex`, `http.ex`, test support + tests
3. Core resources: connectors, items, accounts, transactions, investments, identity + tests
4. Supporting resources: consents, webhooks, categories, loans, merchants, bills + tests
5. Session: `session.ex` + tests
6. Payments: all 7 sub-modules + tests
7. Smart Transfers & Boletos: 4 modules + tests
8. Widgets: Kino, Phoenix LiveComponent, JS hook
9. Polish: formatter, docs, gitignore

---

## 8. Dependencies (mix.exs)

```elixir
{:req, "~> 0.5"},
{:jason, "~> 1.4"},
{:kino, "~> 0.14", optional: true},
{:phoenix_live_view, "~> 1.0", optional: true},
# dev/test
{:plug, "~> 1.16", only: :test},
{:bandit, "~> 1.0", only: :test},
{:ex_doc, "~> 0.34", only: :dev, runtime: false}
```

---

## 9. Architectural Notes

- **Token expiration**: API key (X-API-KEY) = 2 hours, connect token = 30 minutes. Auth plugin handles API key refresh. Connect token expiry is the consumer's responsibility (create a new session or re-fetch token).
- **Concurrent auth race**: Multiple requests can trigger simultaneous re-auth. Acceptable because `POST /auth` is idempotent. Redundant calls are harmless.
- **Req step ordering**: Must verify `request_steps` and `response_steps` lists after construction. Camel conversion before encode_body, snake conversion after decode_body.
- **Query param conversion**: Required params (e.g., `itemId`) are hardcoded in each resource function. Optional params from `opts` are converted by `Pluggy.HTTP` using `KeyTransform.to_camel_string/1`.
- **Session as struct, not GenServer**: The `Pluggy.Session` is a plain struct with functional transformations. State management is delegated to the caller's process (LiveView socket, Livebook variables). This avoids process overhead and fits naturally into both Phoenix and Livebook paradigms.
