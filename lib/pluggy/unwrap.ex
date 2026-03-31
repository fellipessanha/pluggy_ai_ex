defmodule Pluggy.Unwrap do
  @moduledoc """
  Utilities for unwrapping paginated Pluggy API responses.

  Pluggy list endpoints return a paginated map:

      %{results: [items...], page: 1, total_pages: 3, total: 150}

  This module provides helpers for working with these responses:

    * `results/1` — extract the `:results` list from a single page;
      also accepts cursor tuples from `list_with_cursor`
    * `stream_results/1` — lazily stream pages from a cursor result
    * `all_results/1` — eagerly collect and flatten all pages into one list

  All functions accept `{:ok, body}` or `{:error, reason}` tuples and
  propagate errors unchanged. `results/1` also accepts a bare
  `%Req.Response{}` struct and cursor tuples for convenience.

  ## Req plugin

  `attach/2` adds a response step to a `Req.Request` that automatically
  unwraps paginated responses.
  """

  alias Pluggy.{Error, HTTP}
  require Logger

  @typedoc "A paginated API response body."
  @type paginated :: %{
          results: list(),
          page: pos_integer(),
          total_pages: non_neg_integer(),
          total: non_neg_integer()
        }

  @typedoc "A cursor-paginated result from `list_with_cursor`."
  @type cursor_result :: {:ok, paginated(), HTTP.Cursor.t() | nil} | {:error, Error.t()}

  @doc false
  defguard is_paginated(body)
           when is_map_key(body, :results) and
                  is_map_key(body, :page) and
                  is_map_key(body, :total_pages)

  @doc """
  Extracts the `:results` list from a paginated response.

  Accepts `{:ok, body}`, `{:ok, body, cursor}`, `{:error, reason}`, or a
  bare `%Req.Response{}`. Returns the body unchanged when it is not a
  paginated map.

  ## Examples

      iex> Pluggy.Unwrap.results({:ok, %{results: [1, 2], page: 1, total_pages: 1, total: 2}})
      {:ok, [1, 2]}

      iex> Pluggy.Unwrap.results({:ok, %{id: "single"}})
      {:ok, %{id: "single"}}

      iex> Pluggy.Unwrap.results(%Req.Response{status: 200, body: %{results: [1, 2], page: 1, total_pages: 1, total: 2}})
      {:ok, [1, 2]}

      iex> Pluggy.Unwrap.results({:error, %Pluggy.Error{code: 500, message: "boom"}})
      {:error, %Pluggy.Error{code: 500, message: "boom"}}
  """
  @spec results(
          Req.Response.t()
          | {:ok, map(), nil}
          | {:ok, map(), HTTP.Cursor.t()}
          | {:ok, map()}
          | {:error, term()}
        ) ::
          {:ok, list() | term()} | {:error, term()}
  def results(%Req.Response{} = response), do: results({:ok, response.body})
  def results({:ok, body, _cursor}), do: results({:ok, body})
  def results({:ok, body}) when is_paginated(body), do: body.results
  def results(body) when is_paginated(body), do: body.results
  def results({:ok, body}), do: body
  def results({:error, _} = error), do: error

  @doc """
  Bang variant of `results/1` — extracts the `:results` list on success
  or raises on error.

  Also accepts cursor tuples from `list_with_cursor`.

  ## Examples

      iex> Pluggy.Unwrap.results!({:ok, %{results: [1, 2], page: 1, total_pages: 1, total: 2}})
      [1, 2]

      iex> Pluggy.Unwrap.result({:error, %Pluggy.Error{code: 500, message: "boom"}})
      {:error, %Pluggy.Error{code: 500, message: "boom"}}
  """
  @spec result({:ok, term()} | {:error, term()}) :: {:ok, term()} | {:error, term()}
  def result({:ok, body}) when is_paginated(body) do
    if body.total_pages > body.page do
      Logger.warning(
        "Pluggy response has more pages (page #{body.page} of #{body.total_pages}). " <>
          "Use Unwrap.all_pages/2 to fetch all pages."
      )
    end

    body
  end

  def result({:ok, body} = _ok), do: body
  def result({:error, _} = error), do: error

  @doc """
  Unwraps a response tuple, returning the value on success or raising on error.

  ## Examples

      iex> Pluggy.Unwrap.result!({:ok, %{id: "single"}})
      %{id: "single"}
  """
  @spec results!(
          Req.Response.t()
          | {:ok, term(), nil}
          | {:ok, term(), HTTP.Cursor.t()}
          | {:ok, term()}
          | {:error, term()}
        ) ::
          term()
  def results!(response) do
    case results(response) do
      {:error, %Error{} = error} ->
        raise RuntimeError, "Pluggy API error: #{error.message} (code: #{error.code})"

      result ->
        result
    end
  end

  @doc """
  Returns a lazy stream of pages from a cursor-paginated result.

  Each stream element is one page's `:results` list. Accepts the return
  value of a `list_with_cursor` call.

  Raises on errors encountered during pagination. Use `all_results/1`
  if you prefer error tuples.

  ## Examples

      {:ok, data, cursor} = Pluggy.Connectors.list_with_cursor(client)

      {:ok, data, cursor}
      |> Pluggy.Unwrap.stream_results()
      |> Enum.take(2)
      #=> [[%{id: 201, ...}, ...], [%{id: 301, ...}, ...]]
  """
  @spec stream_results(cursor_result()) :: Enumerable.t()
  def stream_results({:ok, %{} = response, cursor}) when is_paginated(response) do
    Stream.unfold({:emit, response, cursor}, fn
      {:emit, response, cursor} ->
        {response, {:fetch, cursor}}

      {:fetch, %HTTP.Cursor{} = cursor} ->
        case HTTP.with_cursor(cursor) do
          {:ok, %{} = next_results, next_cursor} ->
            {next_results, {:fetch, next_cursor}}

          {:error, error} ->
            raise "Pluggy pagination error: #{inspect(error)}"
        end

      {:fetch, nil} ->
        nil
    end)
  end

  def stream_results({:error, _} = error) do
    raise "Cannot stream results from error: #{inspect(error)}"
  end

  @doc """
  Collects all items across every page into a single flat list.

  Accepts the return value of a `list_with_cursor` call. Fetches all
  remaining pages eagerly and returns `{:ok, items}` or `{:error, reason}`
  if any page fetch fails.

  ## Examples

      Pluggy.Connectors.list_with_cursor(client)
      |> Pluggy.Unwrap.all_results()
      #=> [%{id: 201, ...}, %{id: 202, ...}, ...]
  """
  @spec all_results(cursor_result()) :: {:ok, list()} | {:error, Error.t()}
  def all_results({:error, _} = error), do: error

  def all_results({:ok, _, _} = cursor_result) do
    cursor_result
    |> stream_results()
    |> Enum.to_list()
    |> Enum.flat_map(fn response -> results!(response) end)
  rescue
    e in RuntimeError -> {:error, e}
  end

  # -- Req plugin --------------------------------------------------------

  @doc """
  Attaches an unwrap response step to a `Req.Request`.

  The step transforms paginated response bodies according to the given mode.
  Non-paginated responses (e.g. single-resource GETs) pass through unchanged.

  ## Modes

    * `:results` — replaces the body with the `:results` list

  ## Usage

      req = Pluggy.Unwrap.attach(req, :results)

      # Now paginated responses return just the items list:
      {:ok, %Req.Response{body: items}} = Req.request(req, url: "/transactions", ...)
  """
  @spec attach(Req.Request.t(), :results) :: Req.Request.t()
  def attach(%Req.Request{} = req, mode) when mode in [:results] do
    req
    |> Req.Request.register_options([:pluggy_unwrap_mode])
    |> Req.Request.merge_options(pluggy_unwrap_mode: mode)
    |> Req.Request.append_response_steps(pluggy_unwrap: &unwrap_step/1)
  end

  defp unwrap_step({req, %Req.Response{status: status, body: _body} = response})
       when status in 200..299 do
    case apply_mode(req.options[:pluggy_unwrap_mode], response) do
      {:ok, unwrapped} -> {req, %{response | body: unwrapped}}
      _ -> {req, response}
    end
  end

  defp unwrap_step({req, response}), do: {req, response}

  defp apply_mode(:results, %Req.Response{} = response), do: {:ok, results(response)}
end
