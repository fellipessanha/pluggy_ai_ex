defmodule Pluggy.Auth do
  @moduledoc """
  Req plugin that handles Pluggy API authentication.

  Attaches two steps to a `Req.Request`:

    * **Request step** (`pluggy_auth`): ensures an API key is present by calling
      `POST /auth` if needed, then sets the `x-api-key` header.

    * **Response step** (`pluggy_retry_auth`): on a 401 response, re-authenticates
      and replays the request once.

  ## Usage

      req = Req.new(base_url: "https://api.pluggy.ai")
      req = Pluggy.Auth.attach(req, "client_id", "client_secret")
  """

  @doc """
  Attaches the auth plugin to a `Req.Request`.

  Registers the following custom options:

    * `:pluggy_client_id` - Pluggy client ID
    * `:pluggy_client_secret` - Pluggy client secret
    * `:pluggy_api_key` - Cached API key (set automatically after first auth)
    * `:pluggy_auth_retried` - Flag to prevent infinite retry loops
  """
  @spec attach(Req.Request.t(), String.t(), String.t()) :: Req.Request.t()
  def attach(%Req.Request{} = req, client_id, client_secret) do
    req
    |> Req.Request.register_options([
      :pluggy_client_id,
      :pluggy_client_secret,
      :pluggy_api_key,
      :pluggy_auth_retried
    ])
    |> Req.Request.merge_options(
      pluggy_client_id: client_id,
      pluggy_client_secret: client_secret,
      pluggy_auth_retried: false
    )
    |> Req.Request.prepend_request_steps(pluggy_auth: &auth_step/1)
    |> Req.Request.append_response_steps(pluggy_retry_auth: &retry_auth_step/1)
  end

  defp auth_step(%Req.Request{} = req) do
    case req.options[:pluggy_api_key] do
      nil ->
        case authenticate(req) do
          {:ok, api_key} ->
            req
            |> Req.Request.merge_options(pluggy_api_key: api_key)
            |> Req.Request.put_header("x-api-key", api_key)

          {:error, reason} ->
            {req, Req.Response.new(status: 401, body: %{"message" => "Auth failed: #{reason}"})}
        end

      api_key ->
        Req.Request.put_header(req, "x-api-key", api_key)
    end
  end

  defp retry_auth_step({req, %Req.Response{status: 401} = response}) do
    if req.options[:pluggy_auth_retried] do
      {req, response}
    else
      case authenticate(req) do
        {:ok, api_key} ->
          updated_req =
            req
            |> Req.Request.merge_options(
              pluggy_api_key: api_key,
              pluggy_auth_retried: true
            )
            |> Req.Request.put_header("x-api-key", api_key)

          {_, response_or_exception} = Req.Request.run_request(updated_req)

          {Req.Request.halt(req, response_or_exception), response_or_exception}

        {:error, _reason} ->
          {req, response}
      end
    end
  end

  defp retry_auth_step({req, response}), do: {req, response}

  @doc false
  def authenticate(%Req.Request{} = req) do
    client_id = req.options[:pluggy_client_id]
    client_secret = req.options[:pluggy_client_secret]
    base_url = req.options[:base_url] || Pluggy.base_url()

    # Use a fresh Req request to avoid recursion through the auth plugin
    auth_req =
      Req.new(
        base_url: base_url,
        headers: [{"content-type", "application/json"}, {"accept", "application/json"}]
      )

    case Req.post(auth_req,
           url: "/auth",
           json: %{"clientId" => client_id, "clientSecret" => client_secret}
         ) do
      {:ok, %Req.Response{status: 200, body: %{"apiKey" => api_key}}} ->
        {:ok, api_key}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "auth returned #{status}: #{inspect(body)}"}

      {:error, exception} ->
        {:error, "auth request failed: #{Exception.message(exception)}"}
    end
  end
end
