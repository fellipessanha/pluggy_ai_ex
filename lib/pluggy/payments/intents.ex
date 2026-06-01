defmodule Pluggy.Payments.Intents do
  @moduledoc """
  Functions for interacting with the Pluggy Payment Intents API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/payments/intents"

  @doc """
  Creates a new payment intent.

  ## Examples

      Pluggy.Payments.Intents.create(client, %{paymentRequestId: "request-uuid-001"})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, "#{@prefix_url}", json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Lists payment intents.

  ## Options

    * `:page` - Page number for pagination

  ## Examples

      Pluggy.Payments.Intents.list(client)
      Pluggy.Payments.Intents.list(client, page: 2)
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}", params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []), do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Gets a payment intent by ID.

  ## Examples

      Pluggy.Payments.Intents.get(client, "intent-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))
end
