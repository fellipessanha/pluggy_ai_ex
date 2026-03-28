defmodule Pluggy.Transactions do
  @moduledoc """
  Functions for interacting with the Pluggy Transactions API.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @doc """
  Lists transactions for a given account.

  ## Options

    * `:from` - Start date filter
    * `:to` - End date filter
    * `:page_size` - Number of results per page (1-500)
    * `:page` - Page number
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    HTTP.get(client, "/transactions", params: [account_id: account_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, account_id, opts \\ []),
    do: Unwrap.result!(list(client, account_id, opts))

  @doc """
  Gets a transaction by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "/transactions/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))

  @doc """
  Updates a transaction (e.g. to change its category).
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "/transactions/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs), do: Unwrap.result!(update(client, id, attrs))
end
