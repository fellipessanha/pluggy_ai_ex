defmodule Pluggy.Webhooks do
  @moduledoc """
  Functions for interacting with the Pluggy Webhooks API.

  Webhooks allow you to receive real-time notifications when events occur
  in your Pluggy account (e.g. when an item is created or updated).
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/webhooks"

  @doc """
  Lists all webhooks for the account.

  ## Examples

      Pluggy.Webhooks.list(client)
  """
  @spec list(Client.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client) do
    HTTP.get(client, @prefix_url)
  end

  @spec list!(Client.t()) :: term()
  def list!(%Client{} = client), do: HTTP.unwrap_tuple!(list(client))

  @doc """
  Creates a new webhook.

  ## Examples

      Pluggy.Webhooks.create(client, %{event: "item/created", url: "https://example.com/hook", headers: %{}})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, @prefix_url, json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Gets a webhook by ID.

  ## Examples

      Pluggy.Webhooks.get(client, "webhook-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Updates a webhook by ID.

  ## Examples

      Pluggy.Webhooks.update(client, "webhook-uuid-001", %{url: "https://example.com/new-hook"})
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs), do: HTTP.unwrap_tuple!(update(client, id, attrs))

  @doc """
  Deletes a webhook by ID.

  ## Examples

      Pluggy.Webhooks.delete(client, "webhook-uuid-001")
  """
  @spec delete(Client.t(), String.t()) :: {:ok, nil} | {:error, Pluggy.Error.t()}
  def delete(%Client{} = client, id) do
    HTTP.delete(client, "#{@prefix_url}/#{id}")
  end

  @spec delete!(Client.t(), String.t()) :: nil
  def delete!(%Client{} = client, id), do: HTTP.unwrap_tuple!(delete(client, id))
end
