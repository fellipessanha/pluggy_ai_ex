defmodule Pluggy.Endpoints do
  @moduledoc """
  API endpoint modules generated at compile time — one `Pluggy.<Tag>` module per
  tag in the `paths` section of the OpenAPI spec, with a function per operation.

  Each generated function takes a `Pluggy.Client` first, then the operation's
  required path/query parameters positionally, an `attrs` map for the request
  body (when the operation has one), and a trailing `opts \\\\ []` keyword list for
  optional query parameters. Every function has a `!` variant that unwraps the
  result and raises on error; list operations that page also get a
  `<fun>_with_cursor` variant (see `Pluggy.HTTP.with_cursor/1`).

      Pluggy.Account.list(client, item_id)      #=> {:ok, %{results: [...]}}
      Pluggy.Transaction.get!(client, txn_id)   #=> a transaction map

  Parameters named `<...>Id` that are UUIDs get an extractor (e.g.
  `account_id/1`) so a schema struct or map can be passed in place of the raw id.

  Modules are generated, not hand-written: editing `priv/oas3.json` updates them
  on the next compile (wired via `@external_resource`). The curated
  `Pluggy.Payments.*` modules and `Pluggy.Auth` cover the skipped tags.
  """

  alias Pluggy.OAS.{Codegen, Operation, Spec}

  @external_resource Spec.path()

  # Tags served by curated hand-written modules (Payments.*) or the client (Auth).
  @skip_tags MapSet.new([
               "Auth",
               "Automatic PIX",
               "Payment Customer",
               "Payment Intent",
               "Payment Recipient",
               "Payment Request",
               "Payment Schedule"
             ])

  @skip_modules @skip_tags
                |> Enum.map(&Module.concat(Pluggy, Operation.tag_module(&1)))
                |> MapSet.new()

  @endpoints Spec.load!()
             |> Operation.endpoints()
             |> Enum.reject(&MapSet.member?(@skip_modules, &1.module))

  @doc false
  # The grouped endpoint surface actually generated (`:single` and `:family`
  # entries), for introspection and tests.
  def endpoints, do: @endpoints

  @endpoints
  |> Enum.group_by(& &1.module)
  |> Enum.each(fn {module, entries} ->
    Module.create(module, Codegen.endpoint_module_body(entries), Macro.Env.location(__ENV__))
  end)
end
