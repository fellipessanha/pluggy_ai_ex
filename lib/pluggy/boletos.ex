defmodule Pluggy.Boletos do
  @moduledoc """
  Functions for interacting with the Pluggy Boletos API.

  A boleto is a Brazilian payment slip. This module also provides functions
  for managing boleto connections, which link a boleto to a bank item.
  """

  alias Pluggy.{Client, HTTP}

  @boletos_url "/boletos"
  @connections_url "/boleto-connections"

  @doc """
  Creates a new boleto.

  ## Examples

      Pluggy.Boletos.create(client, %{amount: 100.0, due_date: "2024-01-15"})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, @boletos_url, json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Gets a boleto by ID.

  ## Examples

      Pluggy.Boletos.get(client, "boleto-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@boletos_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Cancels a boleto by ID.

  Returns `{:ok, nil}` on success.

  ## Examples

      Pluggy.Boletos.cancel(client, "boleto-uuid-001")
  """
  @spec cancel(Client.t(), String.t()) :: {:ok, nil} | {:error, Pluggy.Error.t()}
  def cancel(%Client{} = client, id) do
    HTTP.post(client, "#{@boletos_url}/#{id}/cancel")
  end

  @spec cancel!(Client.t(), String.t()) :: nil
  def cancel!(%Client{} = client, id), do: HTTP.unwrap_tuple!(cancel(client, id))

  @doc """
  Creates a new boleto connection.

  ## Examples

      Pluggy.Boletos.create_connection(client, %{boleto_id: "boleto-uuid-001", item_id: "item-uuid-001"})
  """
  @spec create_connection(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_connection(%Client{} = client, attrs) do
    HTTP.post(client, @connections_url, json: attrs)
  end

  @spec create_connection!(Client.t(), map()) :: term()
  def create_connection!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_connection(client, attrs))

  @doc """
  Creates a boleto connection from an existing item.

  ## Examples

      Pluggy.Boletos.create_connection_from_item(client, %{item_id: "item-uuid-001"})
  """
  @spec create_connection_from_item(Client.t(), map()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_connection_from_item(%Client{} = client, attrs) do
    HTTP.post(client, "#{@connections_url}/from-item", json: attrs)
  end

  @spec create_connection_from_item!(Client.t(), map()) :: term()
  def create_connection_from_item!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_connection_from_item(client, attrs))
end
