defmodule Pluggy.Payments.Customers do
  @moduledoc """
  Functions for interacting with the Pluggy Payments Customers API.

  A customer represents an individual or business entity in the Pluggy payments system.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/payments/customers"

  @doc """
  Lists payment customers.

  ## Options

    * `:page_size` - Number of results per page
    * `:page` - Page number
    * `:name` - Filter by customer name
    * `:email` - Filter by customer email
    * `:cpf` - Filter by CPF (individual tax number)
    * `:cnpj` - Filter by CNPJ (company tax number)

  ## Examples

      Pluggy.Payments.Customers.list(client)
      Pluggy.Payments.Customers.list(client, page: 1, page_size: 20)
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []),
    do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Creates a new payment customer.

  ## Examples

      Pluggy.Payments.Customers.create(client, %{name: "Test Customer", taxNumber: "12345678901"})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, @prefix_url, json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Gets a payment customer by ID.

  ## Examples

      Pluggy.Payments.Customers.get(client, "customer-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Updates a payment customer.

  ## Examples

      Pluggy.Payments.Customers.update(client, "customer-uuid-001", %{name: "Updated Name"})
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs),
    do: HTTP.unwrap_tuple!(update(client, id, attrs))

  @doc """
  Deletes a payment customer.

  Returns `{:ok, nil}` on success.

  ## Examples

      Pluggy.Payments.Customers.delete(client, "customer-uuid-001")
  """
  @spec delete(Client.t(), String.t()) :: {:ok, nil} | {:error, Pluggy.Error.t()}
  def delete(%Client{} = client, id) do
    HTTP.delete(client, "#{@prefix_url}/#{id}")
  end

  @spec delete!(Client.t(), String.t()) :: nil
  def delete!(%Client{} = client, id), do: HTTP.unwrap_tuple!(delete(client, id))
end
