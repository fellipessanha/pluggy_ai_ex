defmodule Pluggy.SmartTransfers do
  @moduledoc """
  Functions for interacting with the Pluggy Smart Transfers API.

  Smart Transfers allow scheduling and managing automated payment transfers
  via preauthorizations and payments.
  """

  alias Pluggy.{Client, HTTP}

  @preauth_url "/smart-transfers/preauthorizations"
  @payments_url "/smart-transfers/payments"

  @doc """
  Lists all smart transfer preauthorizations.

  ## Examples

      Pluggy.SmartTransfers.list_preauthorizations(client)
  """
  @spec list_preauthorizations(Client.t(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list_preauthorizations(%Client{} = client, opts \\ []) do
    HTTP.get(client, @preauth_url, params: opts)
  end

  @spec list_preauthorizations!(Client.t(), keyword()) :: term()
  def list_preauthorizations!(%Client{} = client, opts \\ []),
    do: HTTP.unwrap_tuple!(list_preauthorizations(client, opts))

  @doc """
  Creates a new smart transfer preauthorization.

  ## Examples

      Pluggy.SmartTransfers.create_preauthorization(client, %{amount: 100.0})
  """
  @spec create_preauthorization(Client.t(), map()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_preauthorization(%Client{} = client, attrs) do
    HTTP.post(client, @preauth_url, json: attrs)
  end

  @spec create_preauthorization!(Client.t(), map()) :: term()
  def create_preauthorization!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_preauthorization(client, attrs))

  @doc """
  Gets a smart transfer preauthorization by ID.

  ## Examples

      Pluggy.SmartTransfers.get_preauthorization(client, "preauth-uuid")
  """
  @spec get_preauthorization(Client.t(), String.t()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def get_preauthorization(%Client{} = client, id) do
    HTTP.get(client, "#{@preauth_url}/#{id}")
  end

  @spec get_preauthorization!(Client.t(), String.t()) :: term()
  def get_preauthorization!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(get_preauthorization(client, id))

  @doc """
  Lists payments for a given smart transfer preauthorization.

  The second argument accepts either a preauthorization ID string or a map
  with an `:id` key — the `:id` field is extracted automatically.

  ## Examples

      Pluggy.SmartTransfers.list_preauthorization_payments(client, "preauth-uuid")
      Pluggy.SmartTransfers.list_preauthorization_payments(client, preauth)
  """
  @spec list_preauthorization_payments(Client.t(), String.t() | map(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list_preauthorization_payments(client, preauth_or_id, opts \\ [])

  def list_preauthorization_payments(%Client{} = client, %{id: id}, opts),
    do: list_preauthorization_payments(client, id, opts)

  def list_preauthorization_payments(%Client{} = client, id, opts) when is_binary(id) do
    HTTP.get(client, "#{@preauth_url}/#{id}/payments", params: opts)
  end

  @spec list_preauthorization_payments!(Client.t(), String.t() | map(), keyword()) :: term()
  def list_preauthorization_payments!(client, preauth_or_id, opts \\ [])

  def list_preauthorization_payments!(%Client{} = client, preauth_or_id, opts),
    do: HTTP.unwrap_tuple!(list_preauthorization_payments(client, preauth_or_id, opts))

  @doc """
  Creates a payment under a smart transfer preauthorization.

  The second argument accepts either a preauthorization ID string or a map
  with an `:id` key — the `:id` field is extracted automatically.

  ## Examples

      Pluggy.SmartTransfers.create_preauthorization_payment(client, "preauth-uuid", %{amount: 50.0})
      Pluggy.SmartTransfers.create_preauthorization_payment(client, preauth, %{amount: 50.0})
  """
  @spec create_preauthorization_payment(Client.t(), String.t() | map(), map()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_preauthorization_payment(client, preauth_or_id, attrs)

  def create_preauthorization_payment(%Client{} = client, %{id: id}, attrs),
    do: create_preauthorization_payment(client, id, attrs)

  def create_preauthorization_payment(%Client{} = client, id, attrs) when is_binary(id) do
    HTTP.post(client, "#{@preauth_url}/#{id}/payments", json: attrs)
  end

  @spec create_preauthorization_payment!(Client.t(), String.t() | map(), map()) :: term()
  def create_preauthorization_payment!(client, preauth_or_id, attrs)

  def create_preauthorization_payment!(%Client{} = client, preauth_or_id, attrs),
    do: HTTP.unwrap_tuple!(create_preauthorization_payment(client, preauth_or_id, attrs))

  @doc """
  Creates a standalone smart transfer payment.

  ## Examples

      Pluggy.SmartTransfers.create_payment(client, %{amount: 100.0})
  """
  @spec create_payment(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_payment(%Client{} = client, attrs) do
    HTTP.post(client, @payments_url, json: attrs)
  end

  @spec create_payment!(Client.t(), map()) :: term()
  def create_payment!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_payment(client, attrs))

  @doc """
  Gets a smart transfer payment by ID.

  ## Examples

      Pluggy.SmartTransfers.get_payment(client, "st-payment-uuid")
  """
  @spec get_payment(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get_payment(%Client{} = client, id) do
    HTTP.get(client, "#{@payments_url}/#{id}")
  end

  @spec get_payment!(Client.t(), String.t()) :: term()
  def get_payment!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(get_payment(client, id))
end
