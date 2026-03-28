defmodule Pluggy.Identity do
  @moduledoc """
  Functions for interacting with the Pluggy Identity API.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @prefix_url "/identity"

  @doc """
  Lists identity data for a given item.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: Unwrap.result!(list(client, item_id, opts))

  @doc """
  Gets identity data by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))
end
