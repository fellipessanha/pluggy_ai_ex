defmodule Pluggy.Transactions do
  @moduledoc """
  Functions for interacting with the Pluggy Transactions API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/transactions"
  @v2_url "/v2#{@prefix_url}"

  @doc """
  Lists transactions for a given account.

  The second argument accepts either an account ID string or an account map
  (e.g. an entry from `Pluggy.Accounts.list/2`) — the `:id` field is extracted
  automatically, making it easy to pipe the two calls together:

      {:ok, %{results: [account | _]}} = Pluggy.Accounts.list(client, item_id)
      Pluggy.Transactions.list(client, account)

  ## Options

  The `:version` option selects the API version and determines which other
  options are accepted:

    * `:version` - API version to use (default: `:v2`)

  ### v2 options (default, `GET /v2/transactions`)

    * `:date_from` - Start date filter (ISO 8601)
    * `:date_to` - End date filter (ISO 8601)
    * `:created_at_from` - Filter by creation date
    * `:ids` - Comma-separated list of transaction IDs
    * `:after` - Cursor token for the next page

  ### v1 options (legacy, `GET /transactions`)

    * `:from` - Start date filter
    * `:to` - End date filter
    * `:page_size` - Number of results per page (1-500)
    * `:page` - Page number

  ## Examples

      # v2 (default)
      Pluggy.Transactions.list(client, "account-uuid-001")
      Pluggy.Transactions.list(client, "account-uuid-001", date_from: "2025-01-01")

      # v1 (legacy)
      Pluggy.Transactions.list(client, "account-uuid-001", version: :v1, from: "2025-01-01")
  """
  @spec list(Client.t(), String.t() | map(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(client, account_or_id, opts \\ [])
  def list(%Client{} = client, %{id: account_id}, opts), do: list(client, account_id, opts)

  def list(%Client{} = client, account_id, opts) when is_binary(account_id) do
    {version, opts} = Keyword.pop(opts, :version, :v2)

    path =
      case version do
        :v1 -> @prefix_url
        :v2 -> @v2_url
      end

    HTTP.get(client, path, params: [account_id: account_id] ++ opts)
  end

  @spec list!(Client.t(), String.t() | map(), keyword()) :: term()
  def list!(client, account_or_id, opts \\ [])

  def list!(%Client{} = client, account_or_id, opts),
    do: HTTP.unwrap_tuple!(list(client, account_or_id, opts))

  @doc """
  Lists transactions with cursor-based pagination.

  The second argument accepts either an account ID string or an account map —
  the `:id` field is extracted automatically.

  For `:v2` (default): Returns `{:ok, response, next}` where `next` is the string
  token from `response.next`, or `nil` when there are no more pages. Pass the
  token as `:after` in the next call.

  For `:v1` (legacy): Returns `{:ok, response, cursor}` where `cursor` is a
  `%Pluggy.HTTP.Cursor{}` when more pages are available, or `nil` when on the last
  page. Pass the cursor to `Pluggy.HTTP.with_cursor/1` to fetch the next page.
  """
  @spec list_with_cursor(Client.t(), String.t() | map(), keyword()) ::
          {:ok, map(), HTTP.Cursor.t() | String.t() | nil} | {:error, Pluggy.Error.t()}
  def list_with_cursor(client, account_or_id, opts \\ [])

  def list_with_cursor(%Client{} = client, %{id: account_id}, opts),
    do: list_with_cursor(client, account_id, opts)

  def list_with_cursor(%Client{} = client, account_id, opts) when is_binary(account_id) do
    version = Keyword.get(opts, :version, :v2)

    case version do
      :v1 ->
        fetcher = fn page -> list(client, account_id, Keyword.put(opts, :page, page)) end
        HTTP.with_cursor(fetcher)

      :v2 ->
        case list(client, account_id, [{:version, :v2} | opts]) do
          {:ok, response} -> {:ok, response, Map.get(response, :next)}
          {:error, _} = error -> error
        end
    end
  end

  @doc """
  Gets a transaction by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Updates a transaction (e.g. to change its category).
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs), do: HTTP.unwrap_tuple!(update(client, id, attrs))
end
