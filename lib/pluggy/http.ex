defmodule Pluggy.HTTP do
  @moduledoc false

  alias Pluggy.{Client, Error, KeyTransform}

  @doc false
  defguard is_paginated(body)
           when is_map_key(body, :results) and
                  is_map_key(body, :page) and
                  is_map_key(body, :total_pages)

  @doc """
  Performs a GET request.

  Query params in `opts[:params]` are converted from snake_case to camelCase.
  """
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def get(%Client{} = client, path, opts \\ []) do
    opts = convert_params(opts)
    request(client, :get, path, opts)
  end

  @doc """
  Performs a POST request.

  The `:json` body is converted from snake_case atom keys to camelCase string keys.
  """
  @spec post(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def post(%Client{} = client, path, opts \\ []) do
    opts = convert_body(opts)
    request(client, :post, path, opts)
  end

  @doc """
  Performs a PATCH request.

  The `:json` body is converted from snake_case atom keys to camelCase string keys.
  """
  @spec patch(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def patch(%Client{} = client, path, opts \\ []) do
    opts = convert_body(opts)
    request(client, :patch, path, opts)
  end

  @doc """
  Performs a DELETE request.
  """
  @spec delete(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def delete(%Client{} = client, path, opts \\ []) do
    request(client, :delete, path, opts)
  end

  # -- Private --

  defp request(%Client{req: req}, method, path, opts) do
    req_opts = Keyword.merge(opts, url: path, method: method)

    case Req.request(req, req_opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: 204}} ->
        {:ok, nil}

      {:ok, %Req.Response{body: body}} when is_map(body) ->
        {:error, Error.from_response(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, %Error{code: status, message: "Unexpected response: #{inspect(body)}"}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, Error.transport(reason)}

      {:error, exception} ->
        {:error, Error.transport(Exception.message(exception))}
    end
  end

  def has_next_page?(%Req.Response{body: %{page: page, total_pages: total_pages}} = response)
      when is_paginated(response.body),
      do: page < total_pages

  def has_next_page?(_), do: false

  defp convert_params(opts) do
    case Keyword.pop(opts, :params) do
      {nil, opts} ->
        opts

      {params, opts} ->
        camel_params =
          Enum.map(params, fn {key, value} ->
            {KeyTransform.to_camel_string(key), value}
          end)

        Keyword.put(opts, :params, camel_params)
    end
  end

  defp convert_body(opts) do
    case Keyword.pop(opts, :json) do
      {nil, opts} -> opts
      {body, opts} -> Keyword.put(opts, :json, KeyTransform.to_camel(body))
    end
  end
end
