defmodule Pluggy.Client do
  @moduledoc """
  The Pluggy API client.

  Holds a configured `Req.Request` with authentication, key transformation,
  and base URL setup.

  ## Usage

      {:ok, client} = Pluggy.Client.new("your_client_id", "your_client_secret")
      client = Pluggy.Client.new!("your_client_id", "your_client_secret")

      # With options
      {:ok, client} = Pluggy.Client.new("id", "secret",
        base_url: "https://custom.api.url",
        req_options: [receive_timeout: 30_000]
      )
  """

  @type t :: %__MODULE__{
          req: Req.Request.t(),
          client_id: String.t(),
          client_secret: String.t()
        }

  defstruct [:req, :client_id, :client_secret]

  @doc """
  Creates a new Pluggy client.

  ## Options

    * `:base_url` - Override the default Pluggy API base URL
    * `:req_options` - Additional options passed to `Req.new/1`
  """
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def new(client_id, client_secret, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, Pluggy.base_url())
    req_options = Keyword.get(opts, :req_options, [])

    req =
      Req.new(
        Keyword.merge(
          [
            base_url: base_url,
            headers: [{"accept", "application/json"}]
          ],
          req_options
        )
      )
      |> Pluggy.Auth.attach(client_id, client_secret)
      |> Req.Request.append_response_steps(pluggy_snake_keys: &snake_keys_step/1)

    case Pluggy.Auth.authenticate(req) do
      {:ok, api_key} ->
        req = Req.Request.merge_options(req, pluggy_api_key: api_key)

        {:ok,
         %__MODULE__{
           req: req,
           client_id: client_id,
           client_secret: client_secret
         }}

      {:error, reason} ->
        {:error, %Pluggy.Error{code: :auth_failed, message: reason}}
    end
  end

  @doc """
  Like `new/3` but raises on error.
  """
  @spec new!(String.t(), String.t(), keyword()) :: t()
  def new!(client_id, client_secret, opts \\ []) do
    case new(client_id, client_secret, opts) do
      {:ok, client} -> client
      {:error, error} -> raise "Failed to create Pluggy client: #{inspect(error)}"
    end
  end

  @doc """
  Requests a connect token.

  ## Options

    * `:item_id` - Optional item ID to create a token for updating an existing item
    * `:options` - Optional map of connect token options
  """
  @spec connect_token(t(), keyword()) :: {:ok, String.t()} | {:error, Pluggy.Error.t()}
  def connect_token(%__MODULE__{} = client, opts \\ []) do
    body =
      opts
      |> Enum.into(%{})
      |> Map.take([:item_id, :options])

    case Pluggy.HTTP.post(client, "/connect_token", json: body) do
      {:ok, %{access_token: token}} -> {:ok, token}
      {:ok, response} -> {:error, %Pluggy.Error{code: :unexpected, message: "Unexpected connect_token response: #{inspect(response)}"}}
      {:error, _} = error -> error
    end
  end

  @doc """
  Like `connect_token/2` but raises on error.
  """
  @spec connect_token!(t(), keyword()) :: String.t()
  def connect_token!(%__MODULE__{} = client, opts \\ []) do
    Pluggy.HTTP.unwrap!(connect_token(client, opts))
  end

  # Response step: convert camelCase keys to snake_case atoms
  defp snake_keys_step({req, %Req.Response{body: body} = response}) when is_map(body) do
    {req, %{response | body: Pluggy.KeyTransform.to_snake(body)}}
  end

  defp snake_keys_step({req, %Req.Response{body: body} = response}) when is_list(body) do
    {req, %{response | body: Pluggy.KeyTransform.to_snake(body)}}
  end

  defp snake_keys_step({req, response}), do: {req, response}
end
