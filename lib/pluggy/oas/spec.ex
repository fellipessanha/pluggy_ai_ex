defmodule Pluggy.OAS.Spec do
  @moduledoc false
  # Access to the OpenAPI 3 spec and pure extraction over it. Centralizes the
  # config-driven path and file read so compile-time codegen modules
  # (e.g. Pluggy.OAS.KeyConversion) share one loader.

  @doc """
  Compile-time path to the OAS spec.

  Config-driven (`:pluggy_ai, :oas_spec_path`); defaults to the vendored copy in
  `priv/oas3.json` for consuming apps that don't override it.
  """
  @spec_path Application.compile_env(
               :pluggy_ai,
               :oas_spec_path,
               Application.app_dir(:pluggy_ai, "priv/oas3.json")
             )

  @spec path() :: Path.t()
  def path, do: @spec_path

  @doc "Reads and decodes the OAS spec. Raises if it's missing or malformed."
  @spec load!() :: map()
  def load!, do: path() |> File.read!() |> JSON.decode!()

  @doc "The `components.schemas` map from a decoded spec (`%{}` if absent)."
  @spec schemas(map()) :: map()
  def schemas(%{} = doc), do: get_in(doc, ["components", "schemas"]) || %{}

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
        render_struct(name, struct_fields(schema), deep_snake(example))
      else
        inspect(deep_snake(example), pretty: true, limit: :infinity)
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

  defp deep_snake(%{} = map), do: Map.new(map, fn {k, v} -> {snake_key(k), deep_snake(v)} end)
  defp deep_snake(list) when is_list(list), do: Enum.map(list, &deep_snake/1)
  defp deep_snake(other), do: other

  defp snake_key(k) when is_binary(k), do: Macro.underscore(k)
  defp snake_key(k), do: k

  defp enum_section([]), do: nil

  defp enum_section(values),
    do: "## Allowed values\n\n" <> Enum.map_join(values, "\n", &"  * `#{inspect(&1)}`")

  @doc """
  Returns the sorted, deduped list of every raw (camelCase) key reachable from a
  response body.

  Walks each response schema, resolving `$ref`s recursively (with a visited-set
  for cycles) and descending through `properties`, `items`, `allOf`/`oneOf`, and
  map-valued `additionalProperties`.
  """
  @spec response_key_strings(map()) :: [String.t()]
  def response_key_strings(%{} = doc) do
    schemas = get_in(doc, ["components", "schemas"]) || %{}

    doc
    |> response_schema_nodes()
    |> Enum.reduce(MapSet.new(), fn node, keys ->
      collect(node, schemas, MapSet.new(), keys)
    end)
    |> Enum.sort()
  end

  # -- starting nodes: every JSON response schema across all paths/methods --
  defp response_schema_nodes(doc) do
    for {_path, methods} <- doc["paths"] || %{},
        is_map(methods),
        {_method, op} <- methods,
        is_map(op),
        {_status, resp} <- op["responses"] || %{},
        is_map(resp),
        schema = get_in(resp, ["content", "application/json", "schema"]),
        is_map(schema),
        do: schema
  end

  # -- recursive key collection; `keys` is a MapSet of raw string keys --
  defp collect(%{"$ref" => "#/components/schemas/" <> name} = node, schemas, visited, keys) do
    keys = collect_without_ref(node, schemas, visited, keys)

    if MapSet.member?(visited, name) do
      keys
    else
      collect(schemas[name], schemas, MapSet.put(visited, name), keys)
    end
  end

  defp collect(node, schemas, visited, keys),
    do: collect_without_ref(node, schemas, visited, keys)

  defp collect_without_ref(%{} = node, schemas, visited, keys) do
    case node do
      %{"properties" => props} when is_map(props) ->
        Enum.reduce(props, MapSet.union(keys, MapSet.new(Map.keys(props))), fn {_k, v}, acc ->
          collect(v, schemas, visited, acc)
        end)

      _ ->
        keys
    end
    |> maybe(node["items"], schemas, visited)
    |> maybe(node["additionalProperties"], schemas, visited)
    |> reduce_list(node["allOf"], schemas, visited)
    |> reduce_list(node["oneOf"], schemas, visited)
  end

  defp collect_without_ref(_node, _schemas, _visited, keys), do: keys

  defp maybe(keys, %{} = child, schemas, visited), do: collect(child, schemas, visited, keys)
  defp maybe(keys, _child, _schemas, _visited), do: keys

  defp reduce_list(keys, list, schemas, visited) when is_list(list),
    do: Enum.reduce(list, keys, &collect(&1, schemas, visited, &2))

  defp reduce_list(keys, _list, _schemas, _visited), do: keys
end
