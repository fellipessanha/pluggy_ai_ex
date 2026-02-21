defmodule Pluggy.Identity do
  @moduledoc """
  Functions for interacting with the Pluggy Identity API.
  """

  alias Pluggy.{Client, HTTP}

  @doc """
  Lists identity data for a given item.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "/identity", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: HTTP.unwrap!(list(client, item_id, opts))

  @doc """
  Gets identity data by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "/identity/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap!(get(client, id))
end
