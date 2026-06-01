defmodule Pluggy.Categories do
  @moduledoc """
  Functions for interacting with the Pluggy Categories API.

  Categories are used to classify transactions. Category rules allow
  automatic categorization of transactions based on defined criteria.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/categories"

  @doc """
  Lists all categories.

  ## Options

    * `:parent_id` - Filter categories by parent ID

  ## Examples

      Pluggy.Categories.list(client)
      Pluggy.Categories.list(client, parent_id: "cat-uuid-001")
  """
  @spec list(Client.t(), keyword()) :: {:ok, list()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: list()
  def list!(%Client{} = client, opts \\ []), do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Gets a category by ID.

  ## Examples

      Pluggy.Categories.get(client, "cat-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: map()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Lists all category rules.

  ## Examples

      Pluggy.Categories.list_rules(client)
  """
  @spec list_rules(Client.t()) :: {:ok, list()} | {:error, Pluggy.Error.t()}
  def list_rules(%Client{} = client) do
    HTTP.get(client, "#{@prefix_url}/rules")
  end

  @spec list_rules!(Client.t()) :: list()
  def list_rules!(%Client{} = client), do: HTTP.unwrap_tuple!(list_rules(client))

  @doc """
  Creates a new category rule.

  ## Examples

      Pluggy.Categories.create_rule(client, %{categoryId: "cat-uuid-001", description: "Coffee"})
  """
  @spec create_rule(Client.t(), map()) :: {:ok, map()} | {:error, Pluggy.Error.t()}
  def create_rule(%Client{} = client, attrs) do
    HTTP.post(client, "#{@prefix_url}/rules", json: attrs)
  end

  @spec create_rule!(Client.t(), map()) :: map()
  def create_rule!(%Client{} = client, attrs), do: HTTP.unwrap_tuple!(create_rule(client, attrs))
end
