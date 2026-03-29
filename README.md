# PluggyAI

[![CI](https://github.com/fellipessanha/pluggy_ai_ex/actions/workflows/ci.yml/badge.svg)](https://github.com/fellipessanha/pluggy_ai_ex/actions/workflows/ci.yml)

An idiomatic Elixir client for the [Pluggy](https://pluggy.ai) open-finance API.

## Why?

[Pluggy](https://pluggy.ai) is an open-finance data aggregation platform for the Brazilian market. It lets you connect to banks and financial institutions to retrieve accounts, transactions, investments, loans, and identity data through a single API.

This library wraps the Pluggy REST API with:

- `{:ok, result}` / `{:error, reason}` tuples and bang (`!`) variants for every endpoint
- Automatic authentication, key caching, and request retries
- Snake-case keys throughout — no `camelCase` leaking into your Elixir code
- An optional **Livebook widget** (`Pluggy.Connect.Kino`) for interactive Connect flows
- An optional **Phoenix LiveView component** (`Pluggy.Connect.Live`) for web apps *(under development)*

## Installation

Add `pluggy_ai` to your dependencies:

```elixir
def deps do
  [
    {:pluggy_ai, github: "fellipessanha/pluggy_ai_ex"}
  ]
end
```

### Optional dependencies

| Dependency | Purpose |
|---|---|
| `{:kino, "~> 0.14"}` | Livebook Connect widget |
| `{:phoenix_live_view, "~> 1.0"}` | Phoenix Connect component |

## Getting credentials

1. Create an account at [pluggy.ai](https://pluggy.ai)
2. Set up [Meu Pluggy](https://github.com/pluggyai/meu-pluggy) to test with sandbox connectors
3. Grab your **Client ID** and **Client Secret** from the Pluggy dashboard

## Quick start

### Create a client

```elixir
{:ok, client} = Pluggy.Client.new("your_client_id", "your_client_secret")
```

### List connectors

```elixir
{:ok, %{results: connectors}} = Pluggy.Connectors.list(client)
```

### Fetch accounts and transactions

```elixir
{:ok, %{results: accounts}} = Pluggy.Accounts.list(client, item.id)

account = List.first(accounts)
transactions = Pluggy.Transactions.list(client, account.id) |> Pluggy.Unwrap.result()
```

### Fetch investments, identity, and loans

```elixir
{:ok, %{results: investments}} = Pluggy.Investments.list(client, item.id)
{:ok, %{results: identities}} = Pluggy.Identity.list(client, item.id)
{:ok, %{results: loans}} = Pluggy.Loans.list(client, item.id)
```

## Pagination with cursors

List endpoints return paginated responses. Every resource module that supports listing exposes a `list_with_cursor` function that returns a cursor you can use to walk through pages:

```elixir
{:ok, first_page, cursor} = Pluggy.Transactions.list_with_cursor(client, account_id)

# cursor is a %Pluggy.HTTP.Cursor{} when more pages exist, or nil on the last page
{:ok, second_page, cursor} = Pluggy.HTTP.with_cursor(cursor)
```

### Collecting all pages

Use `Pluggy.Unwrap.all_results/1` to eagerly fetch and flatten every page into a single list:

```elixir
{:ok, all_transactions} =
  Pluggy.Transactions.list_with_cursor(client, account_id)
  |> Pluggy.Unwrap.all_results()
```

### Streaming pages lazily

Use `Pluggy.Unwrap.stream_results/1` to get a lazy `Stream` — each element is one page's result list. Pages are only fetched as the stream is consumed:

```elixir
Pluggy.Transactions.list_with_cursor(client, account_id)
|> Pluggy.Unwrap.stream_results()
|> Stream.flat_map(& &1)
|> Stream.filter(&(&1.amount > 100))
|> Enum.take(10)
```

## Unwrapping responses

`Pluggy.Unwrap` provides helpers for extracting data from API responses:

| Function | Description |
|---|---|
| `results/1` | Extracts the `:results` list from a paginated `{:ok, body}` tuple |
| `results!/1` | Bang variant — returns the list or raises on error |
| `result/1` | Unwraps `{:ok, body}` to the body value, warns if more pages exist |
| `all_results/1` | Collects all pages from a cursor result into `{:ok, items}` |
| `stream_results/1` | Returns a lazy `Stream` of pages from a cursor result |

```elixir
# Extract results from a single page
{:ok, connectors} = Pluggy.Connectors.list(client) |> Pluggy.Unwrap.results()

# Unwrap any ok tuple
account = Pluggy.Accounts.get(client, account_id) |> Pluggy.Unwrap.result()
```

## Connect widget (Livebook)

Use `Pluggy.Connect.Kino` to render the Pluggy Connect widget directly in a Livebook cell. Pass a client and it handles token generation for you:

```elixir
widget = Pluggy.Connect.Kino.new(client, include_sandbox: true)
```

Then wait for the user to complete the flow:

```elixir
item = Pluggy.Connect.Kino.await_item(widget)
```

See [`demo/pluggy_demo.livemd`](demo/pluggy_demo.livemd) for a full interactive walkthrough.

## Session API

`Pluggy.Session` provides a stateless convenience wrapper that groups a client, connect token, and connected item into a single struct:

```elixir
{:ok, client} = Pluggy.Client.new("client_id", "client_secret")
session = Pluggy.Session.new(client)

{:ok, token, session} = Pluggy.Session.connect_token(session)
# ... user completes Connect flow, returns item_data ...
session = Pluggy.Session.with_item(session, item_data)

{:ok, accounts} = Pluggy.Session.accounts(session)
{:ok, transactions} = Pluggy.Session.transactions(session, account_id)
```

## API modules

| Module | Description |
|---|---|
| `Pluggy.Client` | Authentication and client creation |
| `Pluggy.Connectors` | List, search, and validate financial institution connectors |
| `Pluggy.Items` | Create, update, delete bank connections |
| `Pluggy.Accounts` | List accounts and statements for an item |
| `Pluggy.Transactions` | List and update transactions |
| `Pluggy.Investments` | List investments and investment transactions |
| `Pluggy.Identity` | Retrieve identity/KYC data |
| `Pluggy.Loans` | List loan data |
| `Pluggy.Session` | Stateless session convenience wrapper |
| `Pluggy.Unwrap` | Helpers for unwrapping and paginating API responses |
| `Pluggy.HTTP.Cursor` | Opaque cursor struct for page-by-page iteration |
| `Pluggy.Connect.Kino` | Livebook Connect widget |
| `Pluggy.Connect.Live` | Phoenix LiveView Connect component *(under development)* |

Every resource module exposes `{:ok, _}` / `{:error, _}` functions and bang (`!`) variants that raise on failure.

## License

MIT — see LICENSE.txt.
