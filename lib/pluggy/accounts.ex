defmodule Pluggy.Accounts do
  @moduledoc """
  Functions for interacting with the Pluggy Accounts API.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @prefix_url "/accounts"

  @doc """
  Lists accounts for a given item.

  ## Options

    * `:type` - Filter by account type (`"BANK"` or `"CREDIT"`)
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: Unwrap.result!(list(client, item_id, opts))

  @doc """
  Gets an account by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))

  @doc """
  Fetches statements for an account.
  """
  @spec statements(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def statements(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/statements")
  end

  @spec statements!(Client.t(), String.t()) :: term()
  def statements!(%Client{} = client, id), do: Unwrap.result!(statements(client, id))
end
