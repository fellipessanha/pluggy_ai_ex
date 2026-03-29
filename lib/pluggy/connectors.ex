defmodule Pluggy.Connectors do
  @moduledoc """
  Functions for interacting with the Pluggy Connectors API.

  Connectors represent financial institutions available for connection.
  """

  alias Pluggy.{Client, HTTP}
  @prefix_url "/connectors"

  @doc """
  Lists available connectors.

  Returns the full paginated response map, e.g.
  `%{results: [...], page: 1, total_pages: 3, total: 150}`.  Use
  `Pluggy.Unwrap.results/1` to extract just the results list or
  `list_with_cursor/2` for cursor-based pagination.

  ## Options

    * `:countries` - Filter by country codes
    * `:types` - Filter by connector types
    * `:name` - Filter by name
    * `:sandbox` - Include sandbox connectors
  """
  @spec list(Client.t(), keyword()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: map()
  def list!(%Client{} = client, opts \\ []), do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Lists connectors with cursor-based pagination.

  Returns `{:ok, response, cursor}` where `cursor` is a `%Pluggy.HTTP.Cursor{}`
  when more pages are available, or `nil` when on the last page.

  Pass the cursor to `Pluggy.HTTP.with_cursor/1` to fetch the next page.

  ## Options

  Accepts the same options as `list/2`, plus:

    * `:page` - Page number to fetch (default: 1)

  ## Examples

      {:ok, response, cursor} = Pluggy.Connectors.list_with_cursor(client)
      {:ok, next_response, nil} = Pluggy.HTTP.with_cursor(cursor)

  """
  @spec list_with_cursor(Client.t(), keyword()) ::
          {:ok, map(), HTTP.Cursor.t() | nil} | {:error, Pluggy.Error.t()}
  def list_with_cursor(%Client{} = client, opts \\ []) do
    fetcher = fn page -> list(client, Keyword.put(opts, :page, page)) end
    HTTP.with_cursor(fetcher)
  end

  @doc """
  Gets a connector by ID.

  Returns the full connector response map.

  ## Options

    * `:health_details` - Include health check details
  """
  @spec get(Client.t(), integer(), keyword()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}/#{id}", params: opts)
  end

  @spec get!(Client.t(), integer(), keyword()) :: map()
  def get!(%Client{} = client, id, opts \\ []), do: HTTP.unwrap_tuple!(get(client, id, opts))

  @doc """
  Validates credentials for a connector.

  Returns the full validation response map.
  """
  @spec validate(Client.t(), integer(), map()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def validate(%Client{} = client, id, params) do
    HTTP.post(client, "#{@prefix_url}/#{id}/validate", json: params)
  end

  @spec validate!(Client.t(), integer(), map()) :: map()
  def validate!(%Client{} = client, id, params),
    do: HTTP.unwrap_tuple!(validate(client, id, params))
end
