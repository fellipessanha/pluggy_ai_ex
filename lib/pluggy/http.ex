defmodule Pluggy.HTTP do
  @moduledoc """
  Low-level HTTP interface and cursor-based pagination for the Pluggy API.

  Most users should call the resource modules (`Pluggy.Accounts`,
  `Pluggy.Transactions`, etc.) rather than using this module directly.
  This module is primarily useful for its pagination helpers:

    * `with_cursor/1` — advance a `Pluggy.HTTP.Cursor` to fetch the next page
    * `with_cursor/2` — start cursor-based iteration from a fetcher function
    * `unwrap_tuple!/1` — extract the success value from a result tuple, raising on errors

  ## Cursor-based pagination

  Resource modules that support pagination return
  `{:ok, response, cursor}` tuples. The `cursor` is a `Pluggy.HTTP.Cursor`
  struct that you can pass back to `with_cursor/1` to fetch successive pages.

      fetcher = fn page -> Pluggy.Connectors.list(client, page: page) end
      {:ok, first_page, cursor} = Pluggy.HTTP.with_cursor(fetcher)
      {:ok, second_page, nil}   = Pluggy.HTTP.with_cursor(cursor)
  """

  alias Pluggy.{Client, Error, KeyTransform}

  defmodule Cursor do
    @moduledoc """
    An opaque cursor for paginated API responses.

    Holds a fetcher function and the next page number. Pass to
    `Pluggy.HTTP.next/1` to fetch the next page.
    """

    @type t :: %__MODULE__{
            fetcher: Pluggy.HTTP.fetcher(),
            page: pos_integer()
          }

    @enforce_keys [:fetcher, :page]
    defstruct [:fetcher, :page]
  end

  @typedoc "A function that fetches a specific page number."
  @type fetcher :: (pos_integer() -> {:ok, map()} | {:error, Error.t()})

  @doc false
  defguard is_paginated(body)
           when is_map_key(body, :results) and
                  is_map_key(body, :page) and
                  is_map_key(body, :total_pages)

  @doc false
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def get(%Client{} = client, path, opts \\ []) do
    opts = convert_params(opts)
    request(client, :get, path, opts)
  end

  @doc false
  @spec post(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def post(%Client{} = client, path, opts \\ []) do
    opts = convert_body(opts)
    request(client, :post, path, opts)
  end

  @doc false
  @spec patch(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def patch(%Client{} = client, path, opts \\ []) do
    opts = convert_body(opts)
    request(client, :patch, path, opts)
  end

  @doc false
  @spec delete(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def delete(%Client{} = client, path, opts \\ []) do
    request(client, :delete, path, opts)
  end

  # -- Cursor-based pagination --

  @doc """
  Fetches a page using the given fetcher and returns a cursor for the next page.

  The `fetcher` is a function that accepts a page number and returns
  `{:ok, paginated_response}` or `{:error, error}`.

  Returns `{:ok, response, cursor}` where `cursor` is a `%Cursor{}` struct
  when more pages are available, or `nil` when on the last page.

  ## Examples

      fetcher = fn page -> Pluggy.Connectors.list(client, page: page) end
      {:ok, response, cursor} = Pluggy.HTTP.with_cursor(fetcher)
      {:ok, next_response, nil} = Pluggy.HTTP.with_cursor(cursor)

  """
  @spec with_cursor(fetcher() | Cursor.t(), pos_integer()) ::
          {:ok, map(), Cursor.t() | nil} | {:error, Error.t()}
  def with_cursor(%Cursor{fetcher: fetcher, page: page}) do
    with_cursor(fetcher, page)
  end

  def with_cursor(fetcher, page \\ 1) when is_function(fetcher, 1) and is_integer(page) do
    case fetcher.(page) do
      {:ok, %{page: p, total_pages: tp} = response} when p < tp ->
        {:ok, response, %Cursor{fetcher: fetcher, page: p + 1}}

      {:ok, %{} = response} ->
        {:ok, response, nil}

      {:error, _} = error ->
        error
    end
  end

  # -- Private --

  defp request(%Client{req: req}, method, path, opts) do
    req_opts = Keyword.merge(opts, url: path, method: method)

    case Req.request(req, req_opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: 204}} ->
        {:ok, nil}

      {:ok, %Req.Response{body: body}} when is_map(body) ->
        {:error, Error.from_response(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, %Error{code: status, message: "Unexpected response: #{inspect(body)}"}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, Error.transport(reason)}

      {:error, exception} ->
        {:error, Error.transport(Exception.message(exception))}
    end
  end

  @doc false
  def has_next_page?(%Req.Response{body: %{page: page, total_pages: total_pages}} = response)
      when is_paginated(response.body),
      do: page < total_pages

  def has_next_page?(_), do: false

  @doc """
  Extracts the success value from a result tuple, raising on errors.

  - `{:ok, value}` — returns `value`.
  - `{:ok, a, b, ...}` — returns the tuple with `:ok` removed (e.g. `{a, b}`).
  - `{:error, reason}` — raises `reason`.
  - Anything else — raises `"Unexpected error"`.

  ## Examples

      iex> Pluggy.HTTP.unwrap_tuple!({:ok, 42})
      42

      iex> Pluggy.HTTP.unwrap_tuple!({:ok, :a, :b})
      {:a, :b}

      iex> Pluggy.HTTP.unwrap_tuple!({:ok, 1, 2, 3})
      {1, 2, 3}

      iex> Pluggy.HTTP.unwrap_tuple!({:error, %RuntimeError{message: "boom"}})
      ** (RuntimeError) boom

      iex> Pluggy.HTTP.unwrap_tuple!(:not_a_tuple)
      ** (RuntimeError) Unexpected error

  """
  def unwrap_tuple!({:ok, value}), do: value

  def unwrap_tuple!(ok_tuple) when is_tuple(ok_tuple) and elem(ok_tuple, 0) == :ok,
    do: Tuple.delete_at(ok_tuple, 0)

  def unwrap_tuple!({:error, reason}), do: raise(reason)
  def unwrap_tuple!(_unexpected_tuple), do: raise("Unexpected error")

  defp convert_params(opts) do
    case Keyword.pop(opts, :params) do
      {nil, opts} ->
        opts

      {params, opts} ->
        camel_params =
          Enum.map(params, fn {key, value} ->
            {KeyTransform.to_camel_string(key), value}
          end)

        Keyword.put(opts, :params, camel_params)
    end
  end

  defp convert_body(opts) do
    case Keyword.pop(opts, :json) do
      {nil, opts} -> opts
      {body, opts} -> Keyword.put(opts, :json, KeyTransform.to_camel(body))
    end
  end
end
