defmodule Pluggy.OAS.Schema do
  @moduledoc false
  # Pure extraction over a `components.schemas` entry, consumed by the
  # compile-time generator `Pluggy.Schemas` to build struct/type/doc modules.

  alias Pluggy.OAS.Spec

  @doc """
  Sorted, deduped snake_case field atoms for an object schema's `properties`.

  Uses the same `Macro.underscore/1` transform as `Pluggy.OAS.KeyConversion`, so the atoms
  line up with runtime `Pluggy.KeyTransform.to_snake/1` output — a decoded response map can be
  poured straight into the generated struct.
  """
  @spec struct_fields(map()) :: [atom()]
  def struct_fields(%{"properties" => props}) when is_map(props) do
    props
    |> Map.keys()
    |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def struct_fields(_schema), do: []

  @doc """
  `{field_atom, quoted_type}` pairs for an object schema, sorted by field (aligned with
  `struct_fields/1`), for use in the generated `@type t`.

  Maps each property's OpenAPI `type` to an Elixir type (`string` → `String.t()`, `number` →
  `number()`, `array` → `list()`, `object` → `map()`, etc.). `$ref`/composed properties with no
  `type` become `term()`. Every type is nilable since a bare `defstruct` defaults fields to nil.
  """
  @spec struct_field_types(map()) :: [{atom(), Macro.t()}]
  def struct_field_types(%{"properties" => props}) when is_map(props) do
    props
    |> Enum.map(fn {k, v} -> {k |> Macro.underscore() |> String.to_atom(), field_type(v)} end)
    |> Enum.uniq_by(&elem(&1, 0))
    |> Enum.sort_by(&elem(&1, 0))
  end

  def struct_field_types(_schema), do: []

  # OAS `type` (a string, or an array like ["string","null"] in 3.1) -> quoted Elixir type.
  defp field_type(%{"type" => type}), do: nilable(base_type(scalar(type)))
  defp field_type(_prop), do: quote(do: term())

  defp scalar(type) when is_list(type), do: Enum.find(type, &(&1 != "null"))
  defp scalar(type), do: type

  defp base_type("string"), do: quote(do: String.t())
  defp base_type("integer"), do: quote(do: integer())
  defp base_type("number"), do: quote(do: number())
  defp base_type("boolean"), do: quote(do: boolean())
  defp base_type("array"), do: quote(do: list())
  defp base_type("object"), do: quote(do: map())
  defp base_type(_type), do: quote(do: term())

  defp nilable({:term, _, _} = term), do: term
  defp nilable(type), do: quote(do: unquote(type) | nil)

  @doc "Allowed values for a string-enum schema (`[]` if not an enum)."
  @spec enum_values(map()) :: [String.t()]
  def enum_values(%{"enum" => values}) when is_list(values), do: values
  def enum_values(_schema), do: []

  @doc """
  Builds the `@moduledoc` string for a schema: `description`, an `## Example` section (when the
  schema has a top-level `example`), and an `## Allowed values` list (for enum schemas).
  """
  @spec schema_moduledoc(String.t(), map()) :: String.t()
  def schema_moduledoc(name, %{} = schema) do
    [
      schema["description"] || "`#{name}` schema from the Pluggy OpenAPI spec.",
      example_section(name, schema),
      enum_section(enum_values(schema))
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  # Renders the OAS `example` as an indented Elixir code block. Object schemas render as a
  # populated struct literal (fields default to nil); everything else renders the example value.
  # Keys are snake_cased for display only. ponytail: nested keys stay strings — this is doc text,
  # not decoded data, so there's no reason to mint atoms (the BEAM atom table never GCs). The
  # struct's own field atoms already exist from its `defstruct`, so reusing them costs nothing.
  defp example_section(name, %{"example" => example} = schema) when example != nil do
    rendered =
      if is_map(example) and is_map_key(schema, "properties") do
        render_struct(name, struct_fields(schema), Spec.deep_snake(example))
      else
        inspect(Spec.deep_snake(example), pretty: true, limit: :infinity)
      end

    "## Example\n\n    " <> String.replace(rendered, "\n", "\n    ")
  end

  defp example_section(_name, _schema), do: nil

  # `%Pluggy.Schemas.<Name>{...}` with every field on its own line in `fields` order (sorted,
  # matching the struct definition), populated from the snake_cased example or defaulting to nil.
  # Rendered by hand rather than inspecting a map so the ordering is deterministic — the struct
  # module doesn't exist yet at this point in compilation, so we can't inspect a real struct.
  defp render_struct(name, fields, example) do
    body =
      Enum.map_join(fields, ",\n", fn field ->
        value =
          example |> Map.get(Atom.to_string(field)) |> inspect(pretty: true, limit: :infinity)

        "  #{field}: #{String.replace(value, "\n", "\n  ")}"
      end)

    "%Pluggy.Schemas.#{name}{\n#{body}\n}"
  end

  defp enum_section([]), do: nil

  defp enum_section(values),
    do: "## Allowed values\n\n" <> Enum.map_join(values, "\n", &"  * `#{inspect(&1)}`")
end
