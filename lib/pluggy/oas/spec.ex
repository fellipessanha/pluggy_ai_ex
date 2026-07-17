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
      example_section(schema["example"]),
      enum_section(enum_values(schema))
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  # Raw OAS example rendered as an indented Elixir code block.
  # ponytail: raw (camelCase) example via inspect — stdlib JSON has no pretty-printer and this
  # is dependency-free. Snake-case/JSON rendering only if the doc mismatch ever matters.
  defp example_section(nil), do: nil

  defp example_section(example) do
    body = example |> inspect(pretty: true, limit: :infinity) |> String.replace("\n", "\n    ")
    "## Example\n\n    " <> body
  end

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
