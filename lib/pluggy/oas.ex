defmodule Pluggy.OAS.Spec do
  @moduledoc false
  # Pure extraction of response map keys from a decoded OpenAPI 3 document.
  # No I/O — kept separate so it's testable and callable at compile time.

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

defmodule Pluggy.OAS do
  @moduledoc """
  Maps Pluggy API response keys (camelCase strings) to snake_case atoms.

  The lookup clauses are generated at compile time — one per key reachable from a
  response body in `design-docs/oas3.json` — so known keys become compile-time
  atom literals with no runtime `String.to_atom`.

      Pluggy.OAS.key_as_atom("itemId")   #=> :item_id
      Pluggy.OAS.key_as_atom("unknown")  #=> "unknown"   (passthrough)
      Pluggy.OAS.key_as_atom!("unknown") #=> ** (ArgumentError)
  """

  @spec_path Path.expand("../../design-docs/oas3.json", __DIR__)
  @external_resource @spec_path

  # ponytail: fail loud at compile time if the (untracked) spec is missing.
  unless File.exists?(@spec_path) do
    raise "Pluggy.OAS: OpenAPI spec not found at #{@spec_path}. " <>
            "The spec must be present to compile."
  end

  @key_strings @spec_path
               |> File.read!()
               |> JSON.decode!()
               |> Pluggy.OAS.Spec.response_key_strings()

  @doc """
  Converts a known response key string to its snake_case atom. Unknown keys are
  returned unchanged as strings (no runtime atom creation).
  """
  @spec key_as_atom(String.t()) :: atom() | String.t()
  for k <- @key_strings do
    def key_as_atom(unquote(k)), do: unquote(k |> Macro.underscore() |> String.to_atom())
  end

  def key_as_atom(key) when is_binary(key), do: key

  @doc """
  Like `key_as_atom/1`, but raises `ArgumentError` on an unknown key instead of
  passing it through.
  """
  @spec key_as_atom!(String.t()) :: atom()
  for k <- @key_strings do
    def key_as_atom!(unquote(k)), do: unquote(k |> Macro.underscore() |> String.to_atom())
  end

  def key_as_atom!(key) when is_binary(key),
    do: key |> Macro.underscore() |> String.to_existing_atom()
end
