defmodule Pluggy.Accounts do
  @moduledoc """
  Functions for interacting with the Pluggy Accounts API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/accounts"

  @doc """
  Lists accounts for a given item.

  The second argument accepts either an item ID string or an item map
  (e.g. the result of `Pluggy.Items.get/2`) — the `:id` field is extracted
  automatically.

  ## Options

    * `:type` - Filter by account type (`"BANK"` or `"CREDIT"`)

  ## Examples

      Pluggy.Accounts.list(client, "item-uuid")
      Pluggy.Accounts.list(client, item)   # item is %{id: "item-uuid", ...}
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
  Lists accounts with cursor-based pagination.

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
  Gets an account by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Fetches statements for an account.
  """
  @spec statements(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def statements(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/statements")
  end

  @spec statements!(Client.t(), String.t()) :: term()
  def statements!(%Client{} = client, id), do: HTTP.unwrap_tuple!(statements(client, id))

  @doc """
  Fetches the balance for an account.

  > #### Rate limiting {: .warning}
  >
  > This endpoint may return HTTP 429 (Too Many Requests) if called too frequently.
  > Implement back-off logic if you call this endpoint in tight loops.

  ## Examples

      Pluggy.Accounts.balance(client, "account-uuid-001")
      #=> {:ok, %{id: "account-uuid-001", balance: 1234.56, currency_code: "BRL"}}
  """
  @spec balance(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def balance(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/balance")
  end

  @spec balance!(Client.t(), String.t()) :: term()
  def balance!(%Client{} = client, id), do: HTTP.unwrap_tuple!(balance(client, id))
end
