defmodule Pluggy.Accounts do
  @moduledoc """
  Functions for interacting with the Pluggy Accounts API.
  """

  alias Pluggy.{Client, HTTP}

  @doc """
  Lists accounts for a given item.

  ## Options

    * `:type` - Filter by account type (`"BANK"` or `"CREDIT"`)
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "/accounts", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: HTTP.unwrap!(list(client, item_id, opts))

  @doc """
  Gets an account by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "/accounts/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap!(get(client, id))

  @doc """
  Fetches statements for an account.
  """
  @spec statements(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def statements(%Client{} = client, id) do
    HTTP.get(client, "/accounts/#{id}/statements")
  end

  @spec statements!(Client.t(), String.t()) :: term()
  def statements!(%Client{} = client, id), do: HTTP.unwrap!(statements(client, id))
end
