defmodule Pluggy.OAS.ResponseKeys do
  @moduledoc false
  # Extracts every raw response-body key reachable in the spec, consumed by the
  # compile-time generator `Pluggy.OAS.KeyConversion`.

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
