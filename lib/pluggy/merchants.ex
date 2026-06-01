defmodule Pluggy.Merchants do
  @moduledoc """
  Functions for interacting with the Pluggy Merchants API.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/merchants"

  @doc """
  Lists merchants.

  ## Options

    * `:cnpjs` - Filter by a list of CNPJ strings

  ## Examples

      Pluggy.Merchants.list(client)
      Pluggy.Merchants.list(client, cnpjs: ["12345678901234"])
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    opts =
      case Keyword.pop(opts, :cnpjs) do
        {nil, opts} -> opts
        {cnpjs, opts} -> Keyword.put(opts, :cnpjs, Enum.join(cnpjs, ","))
      end

    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []) do
    HTTP.unwrap_tuple!(list(client, opts))
  end
end
