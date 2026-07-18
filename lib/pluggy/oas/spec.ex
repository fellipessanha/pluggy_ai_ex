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

  # ============================================================================
  # Operations — extraction and code generation for endpoint modules.
  # Consumed by the compile-time generator `Pluggy.Endpoints`, the same way the
  # schema extractors above are consumed by `Pluggy.Schemas`.
  # ============================================================================

  @doc """
  A normalized operation per path+method in the spec, with function names resolved.

  Each entry carries everything the generator needs: the target `module`, the
  resolved `fun` name (heuristic, with the `operationId` as the collision-proof
  fallback), positional `path_params`/`required_query`, `optional_query`, request
  `body?`, response shape (`response_kind`/`response_schema`), and doc material.
  """
  @spec operations(map()) :: [map()]
  def operations(%{} = doc) do
    schemas = schemas(doc)

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

  @doc """
  Tag string → module name segment under `Pluggy`.

  Deterministic PascalCase: `"Boleto Management"` → `"BoletoManagement"`,
  `"Automatic PIX"` → `"AutomaticPix"`.
  """
  @spec tag_module(String.t()) :: String.t()
  def tag_module(tag) do
    tag |> String.split(~r/[^A-Za-z0-9]+/, trim: true) |> Enum.map_join(&String.capitalize/1)
  end

  # -- Code generation ---------------------------------------------------------

  @doc false
  # Quoted body for one endpoint module: moduledoc, id extractors, and per-op
  # functions (base + bang, plus cursor variants for paginated list ops).
  def endpoint_module_body(ops) do
    moduledoc = ops |> List.first() |> Map.fetch!(:tag) |> endpoint_moduledoc()
    blocks = id_helper_asts(ops) ++ Enum.flat_map(ops, &function_asts/1)

    quote do
      @moduledoc unquote(moduledoc)
      (unquote_splicing(blocks))
    end
  end

  defp endpoint_moduledoc(tag) do
    "`#{tag}` API endpoints, generated at compile time from the Pluggy OpenAPI " <>
      "spec (see `Pluggy.Endpoints`)."
  end

  defp id_helper_asts(ops) do
    ops
    |> Enum.flat_map(&(&1.path_params ++ &1.required_query ++ &1.optional_query))
    |> Enum.filter(& &1.extract?)
    |> Enum.uniq_by(& &1.key)
    |> Enum.map(&id_helper_ast/1)
  end

  defp id_helper_ast(%{key: key, name: name}) do
    quote do
      @doc unquote(
             "Extracts the `#{name}` UUID string from a binary, or from a map/struct " <>
               "with an `:id` key."
           )
      @spec unquote(key)(binary() | map()) :: binary()
      def unquote(key)(value) when is_binary(value), do: value
      def unquote(key)(%{id: value}), do: value
    end
  end

  defp function_asts(op) do
    args = head_args(op)
    call = http_call(op)

    base =
      quote do
        @doc unquote(operation_doc(op))
        @spec unquote(op.fun)(unquote_splicing(spec_arg_types(op))) :: unquote(ok_type_ast(op))
        def unquote(op.fun)(unquote_splicing(args)), do: unquote(call)
      end

    bang_name = :"#{op.fun}!"

    bang =
      quote do
        @doc unquote("Same as `#{op.fun}` but returns the value directly, raising on error.")
        @spec unquote(bang_name)(unquote_splicing(spec_arg_types(op))) ::
                unquote(bang_type_ast(op))
        def unquote(bang_name)(unquote_splicing(args)) do
          Pluggy.HTTP.unwrap_tuple!(unquote(op.fun)(unquote_splicing(call_args(op))))
        end
      end

    [base, bang] ++ cursor_asts(op)
  end

  defp cursor_asts(%{paginated?: false}), do: []

  defp cursor_asts(op) do
    args = head_args(op)
    name = :"#{op.fun}_with_cursor"
    bang_name = :"#{op.fun}_with_cursor!"
    # Paginated ops are GETs with no body; call args carry no `attrs`.
    pre_opts = call_args(op) |> Enum.reverse() |> tl() |> Enum.reverse()

    cursor =
      quote do
        @doc unquote("Cursor-paginated `#{op.fun}`; see `Pluggy.HTTP.with_cursor/1`.")
        @spec unquote(name)(unquote_splicing(spec_arg_types(op))) ::
                Pluggy.HTTP.cursor_result()
        def unquote(name)(unquote_splicing(args)) do
          fetcher = fn page ->
            unquote(op.fun)(
              unquote_splicing(pre_opts),
              Keyword.put(unquote(Macro.var(:opts, nil)), :page, page)
            )
          end

          Pluggy.HTTP.with_cursor(fetcher)
        end
      end

    bang =
      quote do
        @doc unquote("Same as `#{op.fun}_with_cursor` but raises on error.")
        def unquote(bang_name)(unquote_splicing(args)) do
          Pluggy.HTTP.unwrap_tuple!(unquote(name)(unquote_splicing(call_args(op))))
        end
      end

    [cursor, bang]
  end

  # -- Argument / call ASTs ----------------------------------------------------

  defp has_opts?(op), do: op.optional_query != []

  defp head_args(op) do
    positional =
      Enum.map(op.path_params, &Macro.var(&1.key, nil)) ++
        Enum.map(op.required_query, &Macro.var(&1.key, nil)) ++
        if(op.body?, do: [Macro.var(:attrs, nil)], else: [])

    opts = if has_opts?(op), do: [quote(do: unquote(Macro.var(:opts, nil)) \\ [])], else: []

    [quote(do: %Pluggy.Client{} = unquote(Macro.var(:client, nil)))] ++ positional ++ opts
  end

  # Same variables as head_args, without patterns/defaults, for internal calls.
  defp call_args(op) do
    [Macro.var(:client, nil)] ++
      Enum.map(op.path_params, &Macro.var(&1.key, nil)) ++
      Enum.map(op.required_query, &Macro.var(&1.key, nil)) ++
      if(op.body?, do: [Macro.var(:attrs, nil)], else: []) ++
      if(has_opts?(op), do: [Macro.var(:opts, nil)], else: [])
  end

  defp http_call(op) do
    http_opts =
      if(op.body?, do: [quote(do: {:json, unquote(Macro.var(:attrs, nil))})], else: []) ++
        case query_ast(op) do
          nil -> []
          query -> [quote(do: {:params, unquote(query)})]
        end

    path = build_path(op.path)

    if http_opts == [] do
      quote(do: Pluggy.HTTP.unquote(op.method)(unquote(Macro.var(:client, nil)), unquote(path)))
    else
      quote do
        Pluggy.HTTP.unquote(op.method)(
          unquote(Macro.var(:client, nil)),
          unquote(path),
          [unquote_splicing(http_opts)]
        )
      end
    end
  end

  defp query_ast(op) do
    req = for p <- op.required_query, do: quote(do: {unquote(p.key), unquote(query_value(p))})
    opts = Macro.var(:opts, nil)

    cond do
      req != [] and has_opts?(op) ->
        quote(do: Keyword.merge([unquote_splicing(req)], unquote(opts)))

      req != [] ->
        quote(do: [unquote_splicing(req)])

      has_opts?(op) ->
        opts

      true ->
        nil
    end
  end

  # Required id params are run through their extractor so a struct/map works too.
  defp query_value(%{key: key, extract?: true}),
    do: quote(do: unquote(key)(unquote(Macro.var(key, nil))))

  defp query_value(%{key: key}), do: Macro.var(key, nil)

  # "/a/{id}/b" -> `"/a/" <> to_string(id) <> "/b"`.
  defp build_path(path) do
    ~r/\{\w+\}/
    |> Regex.split(path, include_captures: true, trim: false)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn
      "{" <> _ = seg ->
        key = seg |> String.trim_leading("{") |> String.trim_trailing("}")
        key = key |> Macro.underscore() |> String.to_atom()
        quote(do: to_string(unquote(Macro.var(key, nil))))

      literal ->
        literal
    end)
    |> Enum.reduce(fn seg, acc -> quote(do: unquote(acc) <> unquote(seg)) end)
  end

  defp spec_arg_types(op) do
    [quote(do: Pluggy.Client.t())] ++
      Enum.map(op.path_params, fn _ -> quote(do: binary() | integer()) end) ++
      Enum.map(op.required_query, fn p ->
        if p.extract?, do: quote(do: binary() | map()), else: quote(do: binary())
      end) ++
      if(op.body?, do: [quote(do: map())], else: []) ++
      if(has_opts?(op), do: [quote(do: keyword())], else: [])
  end

  defp ok_type_ast(op) do
    quote(do: {:ok, unquote(response_type_ast(op))} | {:error, Pluggy.Error.t()})
  end

  defp bang_type_ast(op), do: response_type_ast(op)

  defp response_type_ast(%{response_kind: :struct, response_schema: name}),
    do: quote(do: unquote(Module.concat(Pluggy.Schemas, name)).t())

  defp response_type_ast(%{response_kind: :map}), do: quote(do: map())
  defp response_type_ast(%{response_kind: :none}), do: quote(do: nil)

  # -- Doc string --------------------------------------------------------------

  @doc false
  def operation_doc(op) do
    [
      op.summary || "`#{op.method |> to_string() |> String.upcase()} #{op.path}`",
      parameters_doc(op),
      returns_doc(op)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp parameters_doc(op) do
    lines =
      ["  * `client` — a `Pluggy.Client` struct."] ++
        Enum.map(op.path_params, &param_line/1) ++
        Enum.map(op.required_query, &param_line/1) ++
        body_line(op) ++
        opts_lines(op)

    "## Parameters\n\n" <> Enum.join(lines, "\n")
  end

  defp param_line(p) do
    hint = if p.extract?, do: " Accepts a UUID string or a map/struct with an `:id`.", else: ""
    "  * `#{p.key}` — #{p.description || "the `#{p.name}` parameter."}#{hint}"
  end

  defp body_line(%{body?: true, body_schema: schema}) do
    hint = if is_binary(schema), do: " (a `Pluggy.Schemas.#{schema}`-shaped map)", else: ""
    ["  * `attrs` — the request body#{hint}."]
  end

  defp body_line(_op), do: []

  defp opts_lines(%{optional_query: []}), do: []

  defp opts_lines(%{optional_query: query}) do
    ["  * `opts` — optional query parameters:"] ++
      Enum.map(query, fn p ->
        "    * `#{p.key}` — #{p.description || "the `#{p.name}` filter."}"
      end)
  end

  defp returns_doc(op) do
    type =
      case op.response_kind do
        :struct -> "`{:ok, Pluggy.Schemas.#{op.response_schema}.t()}`"
        :map -> "`{:ok, map()}`"
        :none -> "`{:ok, nil}`"
      end

    base = "## Returns\n\n#{type} on success, or `{:error, Pluggy.Error.t()}`."

    case op.response_example do
      nil ->
        base

      example ->
        rendered = example |> deep_snake() |> inspect(pretty: true, limit: :infinity)
        base <> "\n\n### Example\n\n    " <> String.replace(rendered, "\n", "\n    ")
    end
  end
end
