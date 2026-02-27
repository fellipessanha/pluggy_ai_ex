defmodule Pluggy.Connectors do
  @moduledoc """
  Functions for interacting with the Pluggy Connectors API.

  Connectors represent financial institutions available for connection.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @doc """
  Lists available connectors.

  ## Options

    * `:countries` - Filter by country codes
    * `:types` - Filter by connector types
    * `:name` - Filter by name
    * `:sandbox` - Include sandbox connectors
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, "/connectors", params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []), do: Unwrap.result!(list(client, opts))

  @doc """
  Gets a connector by ID.

  ## Options

    * `:health_details` - Include health check details
  """
  @spec get(Client.t(), integer(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id, opts \\ []) do
    HTTP.get(client, "/connectors/#{id}", params: opts)
  end

  @spec get!(Client.t(), integer(), keyword()) :: term()
  def get!(%Client{} = client, id, opts \\ []), do: Unwrap.result!(get(client, id, opts))

  @doc """
  Validates credentials for a connector.
  """
  @spec validate(Client.t(), integer(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def validate(%Client{} = client, id, params) do
    HTTP.post(client, "/connectors/#{id}/validate", json: params)
  end

  @spec validate!(Client.t(), integer(), map()) :: term()
  def validate!(%Client{} = client, id, params), do: Unwrap.result!(validate(client, id, params))
end
