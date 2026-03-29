defmodule Pluggy.Accounts do
  @moduledoc """
  Functions for interacting with the Pluggy Accounts API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/accounts"

  @doc """
  Lists accounts for a given item.

  ## Options

    * `:type` - Filter by account type (`"BANK"` or `"CREDIT"`)
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: HTTP.unwrap_tuple!(list(client, item_id, opts))

  @doc """
  Lists accounts with cursor-based pagination.

  Returns `{:ok, response, cursor}` where `cursor` is a `%Pluggy.HTTP.Cursor{}`
  when more pages are available, or `nil` when on the last page.

  Pass the cursor to `Pluggy.HTTP.with_cursor/1` to fetch the next page.
  """
  @spec list_with_cursor(Client.t(), String.t(), keyword()) ::
          {:ok, map(), HTTP.Cursor.t() | nil} | {:error, Pluggy.Error.t()}
  def list_with_cursor(%Client{} = client, item_id, opts \\ []) do
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
end
