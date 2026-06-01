defmodule Pluggy.Payments.Recipients do
  @moduledoc """
  Functions for interacting with the Pluggy Payments Recipients API.

  A recipient represents a payment destination registered in the Pluggy platform.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/payments/recipients"

  @doc """
  Lists all payment recipients.

  ## Examples

      Pluggy.Payments.Recipients.list(client)
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []), do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Creates a new payment recipient.

  ## Examples

      Pluggy.Payments.Recipients.create(client, %{name: "Test Recipient", taxNumber: "12345678901"})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, @prefix_url, json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Gets a payment recipient by ID.

  ## Examples

      Pluggy.Payments.Recipients.get(client, "recipient-uuid")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Updates a payment recipient.

  ## Examples

      Pluggy.Payments.Recipients.update(client, "recipient-uuid", %{name: "Updated Name"})
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs), do: HTTP.unwrap_tuple!(update(client, id, attrs))

  @doc """
  Deletes a payment recipient.

  Returns `{:ok, nil}` on success.

  ## Examples

      Pluggy.Payments.Recipients.delete(client, "recipient-uuid")
  """
  @spec delete(Client.t(), String.t()) :: {:ok, nil} | {:error, Pluggy.Error.t()}
  def delete(%Client{} = client, id) do
    HTTP.delete(client, "#{@prefix_url}/#{id}")
  end

  @spec delete!(Client.t(), String.t()) :: nil
  def delete!(%Client{} = client, id), do: HTTP.unwrap_tuple!(delete(client, id))

  @doc """
  Lists institutions available for payment recipients.

  ## Examples

      Pluggy.Payments.Recipients.list_institutions(client)
  """
  @spec list_institutions(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list_institutions(%Client{} = client, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}/institutions", params: opts)
  end

  @spec list_institutions!(Client.t(), keyword()) :: term()
  def list_institutions!(%Client{} = client, opts \\ []),
    do: HTTP.unwrap_tuple!(list_institutions(client, opts))

  @doc """
  Gets a payment recipient institution by ID.

  ## Examples

      Pluggy.Payments.Recipients.get_institution(client, "institution-uuid")
  """
  @spec get_institution(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get_institution(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/institutions/#{id}")
  end

  @spec get_institution!(Client.t(), String.t()) :: term()
  def get_institution!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(get_institution(client, id))
end
