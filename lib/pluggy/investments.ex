defmodule Pluggy.Investments do
  @moduledoc """
  Functions for interacting with the Pluggy Investments API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/investments"

  @doc """
  Lists investments for a given item.

  The second argument accepts either an item ID string or an item map
  (e.g. the result of `Pluggy.Items.get/2`) — the `:id` field is extracted
  automatically.

  ## Examples

      Pluggy.Investments.list(client, "item-uuid")
      Pluggy.Investments.list(client, item)   # item is %{id: "item-uuid", ...}
  """
  @spec list(Client.t(), String.t() | map(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(client, item_or_id, opts \\ [])
  def list(%Client{} = client, %{id: item_id}, opts), do: list(client, item_id, opts)

  def list(%Client{} = client, item_id, opts) when is_binary(item_id) do
    HTTP.get(client, "#{@prefix_url}", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t() | map(), keyword()) :: term()
  def list!(client, item_or_id, opts \\ [])

  def list!(%Client{} = client, item_or_id, opts),
    do: HTTP.unwrap_tuple!(list(client, item_or_id, opts))

  @doc """
  Lists investments with cursor-based pagination.

  The second argument accepts either an item ID string or an item map —
  the `:id` field is extracted automatically.

  Returns `{:ok, response, cursor}` where `cursor` is a `%Pluggy.HTTP.Cursor{}`
  when more pages are available, or `nil` when on the last page.

  Pass the cursor to `Pluggy.HTTP.with_cursor/1` to fetch the next page.
  """
  @spec list_with_cursor(Client.t(), String.t() | map(), keyword()) ::
          {:ok, map(), HTTP.Cursor.t() | nil} | {:error, Pluggy.Error.t()}
  def list_with_cursor(client, item_or_id, opts \\ [])

  def list_with_cursor(%Client{} = client, %{id: item_id}, opts),
    do: list_with_cursor(client, item_id, opts)

  def list_with_cursor(%Client{} = client, item_id, opts) when is_binary(item_id) do
    fetcher = fn page -> list(client, item_id, Keyword.put(opts, :page, page)) end
    HTTP.with_cursor(fetcher)
  end

  @doc """
  Gets an investment by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Fetches transactions for an investment.

  The second argument accepts either an investment ID string or an investment map
  (e.g. an entry from `Pluggy.Investments.list/2`) — the `:id` field is extracted
  automatically:

      {:ok, %{results: [investment | _]}} = Pluggy.Investments.list(client, item_id)
      Pluggy.Investments.transactions(client, investment)
  """
  @spec transactions(Client.t(), String.t() | map(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def transactions(client, investment_or_id, opts \\ [])
  def transactions(%Client{} = client, %{id: id}, opts), do: transactions(client, id, opts)

  def transactions(%Client{} = client, id, opts) when is_binary(id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/transactions", params: opts)
  end

  @spec transactions!(Client.t(), String.t() | map(), keyword()) :: term()
  def transactions!(client, investment_or_id, opts \\ [])

  def transactions!(%Client{} = client, investment_or_id, opts),
    do: HTTP.unwrap_tuple!(transactions(client, investment_or_id, opts))
end
