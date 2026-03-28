defmodule Pluggy.Items do
  @moduledoc """
  Functions for interacting with the Pluggy Items API.

  An item represents a connection to a financial institution.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @prefix_url "/items"

  @doc """
  Creates a new item (connection to a financial institution).
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, "#{@prefix_url}", json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: Unwrap.result!(create(client, attrs))

  @doc """
  Gets an item by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))

  @doc """
  Updates an item.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs), do: Unwrap.result!(update(client, id, attrs))

  @doc """
  Deletes an item.
  """
  @spec delete(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def delete(%Client{} = client, id) do
    HTTP.delete(client, "#{@prefix_url}/#{id}")
  end

  @spec delete!(Client.t(), String.t()) :: term()
  def delete!(%Client{} = client, id), do: Unwrap.result!(delete(client, id))

  @doc """
  Sends MFA (multi-factor authentication) response for an item.
  """
  @spec send_mfa(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def send_mfa(%Client{} = client, id, params) do
    HTTP.post(client, "#{@prefix_url}/#{id}/mfa", json: params)
  end

  @spec send_mfa!(Client.t(), String.t(), map()) :: term()
  def send_mfa!(%Client{} = client, id, params), do: Unwrap.result!(send_mfa(client, id, params))

  @doc """
  Disables automatic sync for an item.
  """
  @spec disable_auto_sync(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def disable_auto_sync(%Client{} = client, id) do
    HTTP.patch(client, "#{@prefix_url}/#{id}/disable-auto-sync")
  end

  @spec disable_auto_sync!(Client.t(), String.t()) :: term()
  def disable_auto_sync!(%Client{} = client, id),
    do: Unwrap.result!(disable_auto_sync(client, id))
end
