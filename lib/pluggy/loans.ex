defmodule Pluggy.Loans do
  @moduledoc """
  Functions for interacting with the Pluggy Loans API.
  """

  alias Pluggy.{Client, HTTP}

  @doc """
  Lists loans for a given item.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "/loans", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: HTTP.unwrap!(list(client, item_id, opts))

  @doc """
  Gets a loan by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "/loans/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap!(get(client, id))
end
