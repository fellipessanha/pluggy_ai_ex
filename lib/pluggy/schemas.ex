defmodule Pluggy.Schemas do
  @moduledoc """
  Struct and type modules generated at compile time — one `Pluggy.Schemas.<Name>` per entry in
  the `components.schemas` section of the OpenAPI spec.

  Each generated module carries the schema's `description` and, when present, its `example` in
  its `@moduledoc`. Object schemas get a `defstruct` whose fields are the snake_case forms of
  their `properties` (aligned with the runtime key transform, so a decoded response map pours
  straight into the struct). String-enum schemas get a `values/0` function instead of a struct;
  composed/other schemas are documentation-only.

      %Pluggy.Schemas.Account{}                #=> a struct with snake_case fields
      Pluggy.Schemas.WebhookEventType.values() #=> ["ITEM/CREATED", ...]

  Modules are generated, not hand-written: editing `priv/oas3.json` adds, removes, or updates
  them on the next compile (wired via `@external_resource`).
  """

  @external_resource Pluggy.OAS.Spec.path()
  @schemas Pluggy.OAS.Spec.load!() |> Pluggy.OAS.Spec.schemas()

  for {name, schema} <- @schemas do
    mod = Module.concat(Pluggy.Schemas, name)
    moduledoc = Pluggy.OAS.Spec.schema_moduledoc(name, schema)

    body =
      cond do
        Map.has_key?(schema, "properties") ->
          fields = Pluggy.OAS.Spec.struct_fields(schema)

          quote do
            @moduledoc unquote(moduledoc)
            @type t :: %__MODULE__{}
            defstruct unquote(fields)
          end

        Map.has_key?(schema, "enum") ->
          values = Pluggy.OAS.Spec.enum_values(schema)

          quote do
            @moduledoc unquote(moduledoc)
            @doc "Allowed values for this enum schema."
            @spec values() :: [String.t()]
            def values, do: unquote(values)
          end

        true ->
          quote do
            @moduledoc unquote(moduledoc)
          end
      end

    Module.create(mod, body, Macro.Env.location(__ENV__))
  end
end
