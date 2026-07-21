defmodule Pluggy.OAS.Codegen do
  @moduledoc false
  # Turns the grouped endpoint entries from `Pluggy.OAS.Operation` into quoted
  # AST: one function per operation (base + bang, plus cursor variants for
  # paginated lists) and one version-dispatch function per family. Consumed by
  # the compile-time generator `Pluggy.Endpoints`. Pure "entry/op maps → AST";
  # depends only on the entry data contract, never on `Operation` internals.

  alias Pluggy.OAS.Spec

  @doc false
  # Quoted body for one endpoint module from its grouped `Operation.endpoints/1`
  # entries: moduledoc, id extractors, per-op functions, and version-dispatch
  # functions.
  def endpoint_module_body(entries) do
    all_ops = Enum.flat_map(entries, &entry_ops/1)
    moduledoc = all_ops |> List.first() |> Map.fetch!(:tag) |> endpoint_moduledoc()
    blocks = id_helper_asts(all_ops) ++ Enum.flat_map(entries, &entry_asts/1)

    quote do
      @moduledoc unquote(moduledoc)
      (unquote_splicing(blocks))
    end
  end

  defp entry_ops(%{kind: :single, op: op}), do: [op]
  defp entry_ops(%{kind: :family, members: members}), do: Enum.map(members, &elem(&1, 1))

  defp entry_asts(%{kind: :single, op: op}), do: function_asts(op)
  defp entry_asts(%{kind: :family} = entry), do: version_family_asts(entry)

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

  # -- Single-operation functions ----------------------------------------------

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

  # -- Version-family functions ------------------------------------------------

  # One function dispatching on a `version:` opt to the matching version's op,
  # plus its bang variant. (No cursor variant: versions can differ in their
  # pagination model — v1 pages, v2 uses an `after` cursor.)
  defp version_family_asts(entry) do
    fun = entry.fun
    args = family_head_args(entry)
    default = entry.default
    module = entry.module
    versions = Enum.map(entry.members, &elem(&1, 0))

    clauses =
      Enum.map(entry.members, fn {version, op} ->
        {:->, [], [[version], family_member_call(op)]}
      end)

    other = Macro.var(:other, nil)

    fallback =
      {:->, [],
       [
         [other],
         quote(
           do:
             raise(
               ArgumentError,
               unquote(
                 "unknown version for #{inspect(module)}.#{fun}, expected one of " <>
                   "#{inspect(versions)}: "
               ) <> inspect(unquote(other))
             )
         )
       ]}

    dispatch = {:case, [], [Macro.var(:version, nil), [do: clauses ++ [fallback]]]}

    body =
      quote do
        {unquote(Macro.var(:version, nil)), unquote(Macro.var(:opts, nil))} =
          Keyword.pop(
            unquote(Macro.var(:opts, nil)),
            :version,
            Pluggy.api_version(unquote(module), unquote(fun), unquote(default))
          )

        unquote(dispatch)
      end

    bang_name = :"#{fun}!"

    base =
      quote do
        @doc unquote(family_doc(entry))
        @spec unquote(fun)(unquote_splicing(family_spec_types(entry))) ::
                unquote(family_ok_type(entry))
        def unquote(fun)(unquote_splicing(args)), do: unquote(body)
      end

    bang =
      quote do
        @doc unquote("Same as `#{fun}` but returns the value directly, raising on error.")
        @spec unquote(bang_name)(unquote_splicing(family_spec_types(entry))) ::
                unquote(family_bang_type(entry))
        def unquote(bang_name)(unquote_splicing(args)) do
          Pluggy.HTTP.unwrap_tuple!(unquote(fun)(unquote_splicing(family_call_args(entry))))
        end
      end

    [base, bang]
  end

  # A member call always merges the caller's `opts` (the `version:` key already
  # popped) into the query, so version-specific filters pass through.
  defp family_member_call(op) do
    http_opts =
      [quote(do: {:params, unquote(family_query_ast(op))})] ++
        if(op.body?, do: [quote(do: {:json, unquote(Macro.var(:attrs, nil))})], else: [])

    quote do
      Pluggy.HTTP.unquote(op.method)(
        unquote(Macro.var(:client, nil)),
        unquote(build_path(op.path)),
        [unquote_splicing(http_opts)]
      )
    end
  end

  defp family_query_ast(op) do
    req = for p <- op.required_query, do: quote(do: {unquote(p.key), unquote(query_value(p))})
    opts = Macro.var(:opts, nil)

    if req == [], do: opts, else: quote(do: Keyword.merge([unquote_splicing(req)], unquote(opts)))
  end

  defp rep_op(entry), do: entry.members |> hd() |> elem(1)

  defp family_head_args(entry) do
    rep = rep_op(entry)

    positional =
      Enum.map(rep.path_params, &Macro.var(&1.key, nil)) ++
        Enum.map(rep.required_query, &Macro.var(&1.key, nil)) ++
        if(rep.body?, do: [Macro.var(:attrs, nil)], else: [])

    [quote(do: %Pluggy.Client{} = unquote(Macro.var(:client, nil)))] ++
      positional ++ [quote(do: unquote(Macro.var(:opts, nil)) \\ [])]
  end

  defp family_call_args(entry) do
    rep = rep_op(entry)

    [Macro.var(:client, nil)] ++
      Enum.map(rep.path_params, &Macro.var(&1.key, nil)) ++
      Enum.map(rep.required_query, &Macro.var(&1.key, nil)) ++
      if(rep.body?, do: [Macro.var(:attrs, nil)], else: []) ++
      [Macro.var(:opts, nil)]
  end

  defp family_spec_types(entry) do
    rep = rep_op(entry)

    [quote(do: Pluggy.Client.t())] ++
      Enum.map(rep.path_params, fn _ -> quote(do: binary() | integer()) end) ++
      Enum.map(rep.required_query, fn p ->
        if p.extract?, do: quote(do: binary() | map()), else: quote(do: binary())
      end) ++
      if(rep.body?, do: [quote(do: map())], else: []) ++
      [quote(do: keyword())]
  end

  defp family_ok_type(entry) do
    quote(do: {:ok, unquote(family_response_union(entry))} | {:error, Pluggy.Error.t()})
  end

  defp family_bang_type(entry), do: family_response_union(entry)

  defp family_response_union(entry) do
    entry.members
    |> Enum.map(fn {_v, op} -> response_type_ast(op) end)
    |> Enum.uniq_by(&Macro.to_string/1)
    |> union_ast()
  end

  defp union_ast([type]), do: type
  defp union_ast([type | rest]), do: quote(do: unquote(type) | unquote(union_ast(rest)))

  defp family_doc(entry) do
    rep = rep_op(entry)
    versions = Enum.map(entry.members, &elem(&1, 0))

    version_line =
      "  * `opts` — optional query parameters, plus `version:` (one of " <>
        "#{inspect(versions)}, default `#{inspect(entry.default)}`) selecting the API version:"

    per_version =
      Enum.map(entry.members, fn {version, op} ->
        method = op.method |> to_string() |> String.upcase()
        filters = Enum.map_join(op.optional_query, ", ", &"`#{&1.key}`")
        filters = if filters == "", do: "", else: " — filters: #{filters}"
        "    * `#{inspect(version)}` → `#{method} #{op.path}`#{filters}"
      end)

    params =
      ["  * `client` — a `Pluggy.Client` struct."] ++
        Enum.map(rep.path_params, &param_line/1) ++
        Enum.map(rep.required_query, &param_line/1) ++
        [version_line | per_version]

    summary =
      rep.summary ||
        "`#{rep.method |> to_string() |> String.upcase()} #{entry.base_path}` (versioned)."

    [summary, "## Parameters\n\n" <> Enum.join(params, "\n"), family_returns(entry)]
    |> Enum.join("\n\n")
  end

  defp family_returns(entry) do
    types =
      entry.members
      |> Enum.map(fn {_v, op} -> op.response_schema end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.map_join(" | ", &"`Pluggy.Schemas.#{&1}.t()`")

    types = if types == "", do: "`map()`", else: types
    "## Returns\n\n`{:ok, #{types}}` on success, or `{:error, Pluggy.Error.t()}`."
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
        rendered = example |> Spec.deep_snake() |> inspect(pretty: true, limit: :infinity)
        base <> "\n\n### Example\n\n    " <> String.replace(rendered, "\n", "\n    ")
    end
  end
end
