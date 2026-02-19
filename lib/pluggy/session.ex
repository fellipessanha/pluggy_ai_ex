defmodule Pluggy.Session do
  @moduledoc """
  A plain struct with functional API for managing a Pluggy connection session.

  A session holds a client, an optional connect token, and the connected item data.
  State lives in the caller's process (LiveView socket, Livebook cell, etc.) —
  no GenServer is used.

  ## Usage

      {:ok, client} = Pluggy.Client.new("client_id", "client_secret")
      session = Pluggy.Session.new(client)

      # Get a connect token for the widget
      {:ok, token, session} = Pluggy.Session.connect_token(session)

      # After widget connection completes
      session = Pluggy.Session.with_item(session, item_data)

      # Fetch resources
      {:ok, accounts} = Pluggy.Session.accounts(session)
      {:ok, txns} = Pluggy.Session.transactions(session, account_id)
  """

  alias Pluggy.{Client, HTTP}

  @type t :: %__MODULE__{
          client: Client.t(),
          connect_token: String.t() | nil,
          item: map() | nil,
          item_id: String.t() | nil,
          connect_token_opts: keyword()
        }

  defstruct [:client, :connect_token, :item, :item_id, connect_token_opts: []]

  @doc """
  Creates a new session from a `Pluggy.Client`.

  ## Options

    * `:webhook_url` - URL for webhook notifications (passed as connect token option)
    * Any other options are stored and passed when creating connect tokens.
  """
  @spec new(Client.t(), keyword()) :: t()
  def new(%Client{} = client, opts \\ []) do
    %__MODULE__{
      client: client,
      connect_token_opts: opts
    }
  end

  @doc """
  Fetches a connect token for this session.

  Returns `{:ok, token, updated_session}` where the updated session caches the token.
  If a token is already cached, returns it without making a new request.
  """
  @spec connect_token(t()) :: {:ok, String.t(), t()} | {:error, Pluggy.Error.t()}
  def connect_token(%__MODULE__{connect_token: token} = session) when is_binary(token) do
    {:ok, token, session}
  end

  def connect_token(%__MODULE__{} = session) do
    case Client.connect_token(session.client, session.connect_token_opts) do
      {:ok, token} ->
        {:ok, token, %{session | connect_token: token}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Refreshes the connect token, ignoring any cached value.
  """
  @spec refresh_connect_token(t()) :: {:ok, String.t(), t()} | {:error, Pluggy.Error.t()}
  def refresh_connect_token(%__MODULE__{} = session) do
    session = %{session | connect_token: nil}
    connect_token(session)
  end

  @doc """
  Sets the connected item data on the session.

  The `item_data` map should contain the item information returned by the
  Pluggy Connect widget's `onSuccess` callback.
  """
  @spec with_item(t(), map()) :: t()
  def with_item(%__MODULE__{} = session, %{} = item_data) do
    item_id =
      Map.get(item_data, :id) ||
        Map.get(item_data, "id") ||
        Map.get(item_data, :item_id) ||
        Map.get(item_data, "itemId")

    %{session | item: item_data, item_id: item_id}
  end

  @doc """
  Returns the underlying `Pluggy.Client` for direct API calls.
  """
  @spec client(t()) :: Client.t()
  def client(%__MODULE__{client: client}), do: client

  # -- Convenience resource accessors --

  @doc """
  Fetches accounts for the connected item.

  Returns `{:error, :no_item}` if no item has been set.
  """
  @spec accounts(t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t() | :no_item}
  def accounts(session, opts \\ [])
  def accounts(%__MODULE__{item_id: nil}, _opts), do: {:error, :no_item}

  def accounts(%__MODULE__{} = session, opts) do
    HTTP.get(session.client, "/accounts", params: [item_id: session.item_id] ++ opts)
  end

  @doc """
  Fetches transactions for a given account ID.

  Returns `{:error, :no_item}` if no item has been set.
  """
  @spec transactions(t(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t() | :no_item}
  def transactions(session, account_id, opts \\ [])
  def transactions(%__MODULE__{item_id: nil}, _account_id, _opts), do: {:error, :no_item}

  def transactions(%__MODULE__{} = session, account_id, opts) do
    HTTP.get(session.client, "/transactions", params: [account_id: account_id] ++ opts)
  end

  @doc """
  Fetches investments for the connected item.
  """
  @spec investments(t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t() | :no_item}
  def investments(session, opts \\ [])
  def investments(%__MODULE__{item_id: nil}, _opts), do: {:error, :no_item}

  def investments(%__MODULE__{} = session, opts) do
    HTTP.get(session.client, "/investments", params: [item_id: session.item_id] ++ opts)
  end

  @doc """
  Fetches identity data for the connected item.
  """
  @spec identity(t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t() | :no_item}
  def identity(session, opts \\ [])
  def identity(%__MODULE__{item_id: nil}, _opts), do: {:error, :no_item}

  def identity(%__MODULE__{} = session, opts) do
    HTTP.get(session.client, "/identity", params: [item_id: session.item_id] ++ opts)
  end

  @doc """
  Fetches loans for the connected item.
  """
  @spec loans(t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t() | :no_item}
  def loans(session, opts \\ [])
  def loans(%__MODULE__{item_id: nil}, _opts), do: {:error, :no_item}

  def loans(%__MODULE__{} = session, opts) do
    HTTP.get(session.client, "/loans", params: [item_id: session.item_id] ++ opts)
  end
end
