defmodule Pluggy.Investments do
  @moduledoc """
  Functions for interacting with the Pluggy Investments API.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @doc """
  Lists investments for a given item.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "/investments", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: Unwrap.result!(list(client, item_id, opts))

  @doc """
  Gets an investment by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "/investments/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))

  @doc """
  Fetches transactions for an investment.
  """
  @spec transactions(Client.t(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def transactions(%Client{} = client, id, opts \\ []) do
    HTTP.get(client, "/investments/#{id}/transactions", params: opts)
  end

  @spec transactions!(Client.t(), String.t(), keyword()) :: term()
  def transactions!(%Client{} = client, id, opts \\ []),
    do: Unwrap.result!(transactions(client, id, opts))
end
