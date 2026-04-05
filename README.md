# PluggyAI

[![CI](https://github.com/fellipessanha/pluggy_ai_ex/actions/workflows/ci.yml/badge.svg)](https://github.com/fellipessanha/pluggy_ai_ex/actions/workflows/ci.yml)

An idiomatic Elixir client for the [Pluggy](https://pluggy.ai) open-finance API.

## Why?

[Pluggy](https://pluggy.ai) is an open-finance data aggregation platform for the Brazilian market. It lets you connect
to banks and financial institutions to retrieve accounts, transactions, investments, loans, and identity data through a
single API.

This library wraps the Pluggy REST API idiomatically with some nice friendly user interface, such as the usual `:ok`,
`:error` tuple syntax and their equivalent `!` methods that raise if the operation is not successful, formatting the
responses into maps with `snake_case` atom keys, pagination unwrappers, and a lot more!

In Pluggy's API, you'll need an **item**, which is a representation of a connection to one of the service's many
**Connectors**. according to [Pluggy's own documentation]
(https://docs.pluggy.ai/docs/item#creating-an-item-institution-authentication-flow),
the best way to do so is to use their provided widget. This library provides a nice wrapper of this widget as both
a `Phoenix.Component`, and a `Kino.JS.Live`, and those modules will only be compiled if the dependencies are found
in your project, so there won't be any unnecessary bloat in your application!

> Warning: The Phoenix.Component is still under development, so it's API is prone to some changes!

## Installation

Add `pluggy_ai` to your dependencies:

```elixir
def deps do
  [
    {:pluggy_ai, "~> 0.1.0"}
  ]
end
```

### Optional dependencies

As stated above, there's wrappers for the connection widget in popular Elixir Frameworks. These are the ones currently
available

| Dependency                       | Purpose                   |
| -------------------------------- | ------------------------- |
| `{:kino, "~> 0.14"}`             | Livebook Connect widget   |
| `{:phoenix_live_view, "~> 1.0"}` | Phoenix Connect component |

## Getting credentials

The best way to test this library -- or to use this for personal finance data, is to use [Meu Pluggy](https://github.com/pluggyai/meu-pluggy).
Read the docs to see what's good about it!

1. Create an account at [pluggy.ai](https://pluggy.ai)
2. Grab your **Client ID** and **Client Secret** from the Pluggy dashboard

## Quick start

See [our Livebook example](./demo/pluggy_demo.livemd) to get a feeling of what's it like to use this library!

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

| Module                | Description                                                 |
| --------------------- | ----------------------------------------------------------- |
| `Pluggy.Client`       | Authentication and client creation                          |
| `Pluggy.Connectors`   | List, search, and validate financial institution connectors |
| `Pluggy.Items`        | Create, update, delete bank connections                     |
| `Pluggy.Accounts`     | List accounts and statements for an item                    |
| `Pluggy.Transactions` | List and update transactions                                |
| `Pluggy.Investments`  | List investments and investment transactions                |
| `Pluggy.Identity`     | Retrieve identity/KYC data                                  |
| `Pluggy.Loans`        | List loan data                                              |
| `Pluggy.Session`      | Stateless session convenience wrapper                       |
| `Pluggy.Unwrap`       | Helpers for unwrapping and paginating API responses         |
| `Pluggy.HTTP.Cursor`  | Opaque cursor struct for page-by-page iteration             |
| `Pluggy.Connect.Kino` | Livebook Connect widget                                     |
| `Pluggy.Connect.Live` | Phoenix LiveView Connect component _(under development)_    |

## License

MIT — see LICENSE.txt.
