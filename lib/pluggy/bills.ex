defmodule Pluggy.Bills do
  @moduledoc """
  Functions for interacting with the Pluggy Bills API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/bills"

  @doc """
  Lists bills for a given account.

  The second argument accepts either an account ID string or an account map
  (e.g. the result of `Pluggy.Accounts.get/2`) — the `:id` field is extracted
  automatically.

  ## Examples

      Pluggy.Bills.list(client, "account-uuid")
      Pluggy.Bills.list(client, account)   # account is %{id: "account-uuid", ...}
  """
  @spec list(Client.t(), String.t() | map(), keyword()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(client, account_or_id, opts \\ [])
  def list(%Client{} = client, %{id: account_id}, opts), do: list(client, account_id, opts)

  def list(%Client{} = client, account_id, opts) when is_binary(account_id) do
    HTTP.get(client, "#{@prefix_url}", params: [account_id: account_id] ++ opts)
  end

  @spec list!(Client.t(), String.t() | map(), keyword()) :: term()
  def list!(client, account_or_id, opts \\ [])

  def list!(%Client{} = client, account_or_id, opts),
    do: HTTP.unwrap_tuple!(list(client, account_or_id, opts))

  @doc """
  Gets a bill by ID.

  ## Examples

      Pluggy.Bills.get(client, "bill-uuid")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id), do: HTTP.unwrap_tuple!(get(client, id))
end
