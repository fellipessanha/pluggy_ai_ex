defmodule Pluggy.Connectors do
  @moduledoc """
  Functions for interacting with the Pluggy Connectors API.

  Connectors represent financial institutions available for connection.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

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
    HTTP.get(client, "/connectors", params: opts)
  end

  @spec list!(Client.t(), keyword()) :: map()
  def list!(%Client{} = client, opts \\ []), do: Unwrap.result!(list(client, opts))

  @doc """
  Lists connectors with cursor-based pagination.

  Returns a three-element success tuple `{:ok, response, next_page}` where
  `response` is the full paginated response map and `next_page` is the next
  page number to fetch, or `nil` when there are no more pages.

  ## Options

  Accepts the same options as `list/2`, plus:

    * `:page` - Page number to fetch (default: 1)

  ## Examples

      {:ok, response, nil} = Pluggy.Connectors.list_with_cursor(client)
      {:ok, response, 2}  = Pluggy.Connectors.list_with_cursor(client, page: 1)

  """
  @spec list_with_cursor(Client.t(), keyword()) ::
          {:ok, map(), non_neg_integer() | nil} | {:error, Pluggy.Error.t()}
  def list_with_cursor(%Client{} = client, opts \\ []) do
    case HTTP.get(client, "/connectors", params: opts) do
      {:ok, %{page: page, total_pages: total_pages} = response} when page < total_pages ->
        {:ok, response, page + 1}

      {:ok, %{} = response} ->
        {:ok, response, nil}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets a connector by ID.

  Returns the full connector response map.

  ## Options

    * `:health_details` - Include health check details
  """
  @spec get(Client.t(), integer(), keyword()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id, opts \\ []) do
    HTTP.get(client, "/connectors/#{id}", params: opts)
  end

  @spec get!(Client.t(), integer(), keyword()) :: map()
  def get!(%Client{} = client, id, opts \\ []), do: Unwrap.result!(get(client, id, opts))

  @doc """
  Validates credentials for a connector.

  Returns the full validation response map.
  """
  @spec validate(Client.t(), integer(), map()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def validate(%Client{} = client, id, params) do
    HTTP.post(client, "/connectors/#{id}/validate", json: params)
  end

  @spec validate!(Client.t(), integer(), map()) :: map()
  def validate!(%Client{} = client, id, params), do: Unwrap.result!(validate(client, id, params))
end
