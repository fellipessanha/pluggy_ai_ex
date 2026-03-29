defmodule Pluggy.Loans do
  @moduledoc """
  Functions for interacting with the Pluggy Loans API.
  """

  alias Pluggy.{Client, HTTP, Unwrap}

  @prefix_url "/loans"

  @doc """
  Lists loans for a given item.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, item_id, opts \\ []) do
    HTTP.get(client, "#{@prefix_url}", params: [item_id: item_id] ++ opts)
  end

  @spec list!(Client.t(), String.t(), keyword()) :: term()
  def list!(%Client{} = client, item_id, opts \\ []),
    do: Unwrap.result!(list(client, item_id, opts))

  @doc """
  Lists loans with cursor-based pagination.

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
  Gets a loan by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: Unwrap.result!(get(client, id))
end
