defmodule Pluggy.OAS.Operation do
  @moduledoc false
  # Extraction of the operation/endpoint data model from the spec's `paths`:
  # normalized operations, the function-name heuristic, and version/family
  # detection. The pure data layer behind the compile-time generator
  # `Pluggy.Endpoints` (which feeds this into `Pluggy.OAS.Codegen`).

  alias Pluggy.OAS.Spec

  @doc """
  A normalized operation per path+method in the spec, with function names resolved.

  Each entry carries everything the generator needs: the target `module`, the
  resolved `fun` name (heuristic, with the `operationId` as the collision-proof
  fallback), positional `path_params`/`required_query`, `optional_query`, request
  `body?`, response shape (`response_kind`/`response_schema`), and doc material.
  """
  @spec operations(map()) :: [map()]
  def operations(%{} = doc) do
    schemas = Spec.schemas(doc)

    ops =
      for {path, item} <- doc["paths"] || %{},
          is_map(item),
          {method, op} <- item,
          http_method?(method),
          is_map(op) do
        normalize_operation(String.to_atom(method), path, op, schemas)
      end

    resolve_collisions(ops)
  end

  @doc """
  The final endpoint surface for the generator: `operations/1` grouped so that
  version variants of one endpoint collapse into a single dispatch function.

  Returns a list of entries, each either:

    * `%{kind: :single, module: mod, op: op}` — one operation, one function.
    * `%{kind: :family, module: mod, fun: atom, default: version, base_path: str, members: [{version, op}]}` —
      several versions of one endpoint (same method + version-stripped path + arg
      shape), served by one function that dispatches on a `version:` opt.
  """
  @spec endpoints(map()) :: [map()]
  def endpoints(%{} = doc) do
    doc
    |> operations()
    |> Enum.group_by(& &1.module)
    |> Enum.flat_map(fn {_module, mod_ops} -> module_endpoints(mod_ops) end)
  end

  @doc """
  Tag string → module name segment under `Pluggy`.

  Deterministic PascalCase: `"Boleto Management"` → `"BoletoManagement"`,
  `"Automatic PIX"` → `"AutomaticPix"`.
  """
  @spec tag_module(String.t()) :: String.t()
  def tag_module(tag) do
    tag |> String.split(~r/[^A-Za-z0-9]+/, trim: true) |> Enum.map_join(&String.capitalize/1)
  end

  # -- Endpoint grouping (version families) ------------------------------------

  defp module_endpoints(mod_ops) do
    {families, singles} =
      mod_ops
      |> Enum.group_by(& &1.family_key)
      |> Map.values()
      |> Enum.split_with(&unifiable_family?/1)

    entries =
      Enum.map(families, &family_entry/1) ++
        for(group <- singles, op <- group, do: %{kind: :single, module: op.module, op: op})

    resolve_endpoint_collisions(entries)
  end

  # A family is unifiable only when its members are true version variants (>1
  # distinct version) AND share the same positional arg shape — otherwise the
  # user gets separate functions.
  defp unifiable_family?([_single]), do: false

  defp unifiable_family?(group) do
    versions = group |> Enum.map(& &1.version) |> Enum.uniq()
    length(versions) == length(group) and same_signature?(group)
  end

  defp same_signature?(group) do
    sigs =
      Enum.map(group, fn op ->
        {Enum.map(op.path_params, & &1.key), Enum.map(op.required_query, & &1.key), op.body?}
      end)

    match?([_], Enum.uniq(sigs))
  end

  defp family_entry(group) do
    members = group |> Enum.map(&{&1.version, &1}) |> Enum.sort_by(&elem(&1, 0))
    rep = List.first(group)

    %{
      kind: :family,
      module: rep.module,
      fun: preferred_fun(rep.method, stripped_path(rep.path)),
      base_path: stripped_path(rep.path),
      default: group |> Enum.max_by(&version_num(&1.version)) |> Map.fetch!(:version),
      members: members
    }
  end

  defp version_num(version),
    do: version |> Atom.to_string() |> String.trim_leading("v") |> String.to_integer()

  # A family's base name could clash with a sibling function; fall back to the
  # version-stripped resource segment (e.g. `:transactions`) if so.
  defp resolve_endpoint_collisions(entries) do
    counts = entries |> Enum.map(&endpoint_name/1) |> Enum.frequencies()
    Enum.map(entries, &maybe_rename_family(&1, counts))
  end

  defp maybe_rename_family(%{kind: :family, fun: fun} = entry, counts) do
    if counts[fun] > 1, do: %{entry | fun: family_fallback(entry)}, else: entry
  end

  defp maybe_rename_family(entry, _counts), do: entry

  defp endpoint_name(%{kind: :family, fun: fun}), do: fun
  defp endpoint_name(%{kind: :single, op: op}), do: op.fun

  defp family_fallback(%{base_path: base_path}) do
    base_path
    |> String.trim_leading("/")
    |> String.split("/")
    |> List.last()
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  # -- Normalization -----------------------------------------------------------

  defp http_method?(m), do: m in ~w(get post put patch delete)

  defp normalize_operation(method, path, op, schemas) do
    tag = op |> Map.get("tags", []) |> List.first() || "Default"
    params = Map.get(op, "parameters", [])
    path_params = for p <- params, p["in"] == "path", do: param_entry(p)
    query = for p <- params, p["in"] == "query", do: param_entry(p)
    {required_query, optional_query} = Enum.split_with(query, & &1.required)
    body = request_body(op)
    resp = success_response(op)
    resp_schema = response_schema_name(resp)

    %{
      tag: tag,
      module: Module.concat(Pluggy, tag_module(tag)),
      method: method,
      path: path,
      op_id: op["operationId"] || "#{method}_#{path}",
      preferred_fun: preferred_fun(method, path),
      version: version_of(path),
      family_key: {method, stripped_path(path)},
      path_params: path_params,
      required_query: required_query,
      optional_query: optional_query,
      body?: body != nil,
      body_schema: body,
      response_schema: resp_schema,
      response_kind: response_kind(resp, resp_schema, schemas),
      paginated?: Enum.any?(query, &(&1.name == "page")),
      summary: op["summary"] || op["description"],
      response_example: response_example(resp)
    }
  end

  defp response_kind(resp, resp_schema, schemas) do
    cond do
      resp_schema && object_schema?(schemas[resp_schema]) -> :struct
      json_response?(resp) -> :map
      true -> :none
    end
  end

  defp param_entry(p) do
    name = p["name"]

    %{
      name: name,
      key: name |> Macro.underscore() |> String.to_atom(),
      required: p["required"] == true,
      description: p["description"],
      extract?: id_param?(name, p["schema"])
    }
  end

  # An `\w+Id` (case-sensitive) query/path param typed as string+uuid: gets the
  # struct/map extractor so callers may pass a schema struct in place of the id.
  defp id_param?(name, %{"type" => "string", "format" => "uuid"}) when is_binary(name),
    do: Regex.match?(~r/^\w+Id$/, name)

  defp id_param?(_name, _schema), do: false

  # nil (no body) | "SchemaName" (named) | :inline (present but unnamed).
  defp request_body(%{"requestBody" => %{"$ref" => ref}}), do: last_segment(ref)

  defp request_body(%{"requestBody" => %{"content" => content}}) do
    case get_in(content, ["application/json", "schema"]) do
      %{"$ref" => ref} -> last_segment(ref)
      _ -> :inline
    end
  end

  defp request_body(_op), do: nil

  defp last_segment(ref), do: ref |> String.split("/") |> List.last()

  # First 2xx response node (by status code order) that has JSON content, or nil.
  defp success_response(op) do
    op
    |> Map.get("responses", %{})
    |> Enum.filter(fn {code, _} -> String.starts_with?(to_string(code), "2") end)
    |> Enum.sort_by(fn {code, _} -> to_string(code) end)
    |> Enum.map(&elem(&1, 1))
    |> List.first()
  end

  defp response_schema_name(nil), do: nil

  defp response_schema_name(resp) do
    case get_in(resp, ["content", "application/json", "schema"]) do
      # `$ref` wins even in the hybrid `{"type":"object","$ref":...}` form.
      %{"$ref" => ref} -> last_segment(ref)
      _ -> nil
    end
  end

  defp json_response?(nil), do: false
  defp json_response?(resp), do: get_in(resp, ["content", "application/json"]) != nil

  defp object_schema?(%{"properties" => props}) when is_map(props), do: true
  defp object_schema?(_schema), do: false

  defp response_example(nil), do: nil

  defp response_example(resp) do
    json = get_in(resp, ["content", "application/json"]) || %{}

    cond do
      is_map(json["examples"]) ->
        case json["examples"] |> Enum.sort_by(&elem(&1, 0)) |> List.first() do
          {_k, %{"value" => value}} -> value
          _ -> nil
        end

      Map.has_key?(json, "example") ->
        json["example"]

      true ->
        nil
    end
  end

  # -- Function-name heuristic (ceiling: operationId fallback on collision) -----

  defp preferred_fun(method, path) do
    segs = path |> String.trim_leading("/") |> String.split("/") |> drop_version()
    last = List.last(segs)

    cond do
      param_segment?(last) -> verb_fun(method)
      length(segs) == 1 -> collection_fun(method)
      true -> segment_fun(last)
    end
  end

  defp drop_version([h | t]), do: if(Regex.match?(~r/^v\d+$/, h), do: t, else: [h | t])
  defp drop_version([]), do: []

  # The `v<n>` path segment as an atom, or `:v1` for the un-versioned (original) path.
  defp version_of(path) do
    case path |> String.trim_leading("/") |> String.split("/") do
      [h | _] -> if Regex.match?(~r/^v\d+$/, h), do: String.to_atom(h), else: :v1
      [] -> :v1
    end
  end

  # Path with any leading `v<n>` segment removed, so version variants share a key.
  defp stripped_path(path) do
    segs = path |> String.trim_leading("/") |> String.split("/") |> drop_version()
    "/" <> Enum.join(segs, "/")
  end

  defp param_segment?("{" <> _ = s), do: String.ends_with?(s, "}")
  defp param_segment?(_), do: false

  defp verb_fun(:get), do: :get
  defp verb_fun(:delete), do: :delete
  defp verb_fun(m) when m in [:patch, :put], do: :update
  defp verb_fun(:post), do: :create

  defp collection_fun(:get), do: :list
  defp collection_fun(:post), do: :create
  defp collection_fun(m) when m in [:patch, :put], do: :update
  defp collection_fun(:delete), do: :delete

  defp segment_fun(seg), do: seg |> String.replace("-", "_") |> String.to_atom()

  # Within each module, any preferred name used by >1 op falls back to the
  # (unique) operationId-derived name for every op that would collide.
  defp resolve_collisions(ops) do
    ops
    |> Enum.group_by(& &1.module)
    |> Enum.flat_map(fn {_module, mod_ops} -> resolve_group(mod_ops) end)
  end

  defp resolve_group(mod_ops) do
    counts = Enum.frequencies(Enum.map(mod_ops, & &1.preferred_fun))
    Enum.map(mod_ops, &resolve_fun(&1, counts))
  end

  defp resolve_fun(op, counts) do
    fun = if counts[op.preferred_fun] > 1, do: fallback_fun(op.op_id), else: op.preferred_fun
    Map.put(op, :fun, fun)
  end

  defp fallback_fun(op_id),
    do: op_id |> String.replace("-", "_") |> String.downcase() |> String.to_atom()
end
