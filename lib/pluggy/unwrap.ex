defmodule Pluggy.Unwrap do
  @moduledoc """
  Utilities for unwrapping paginated Pluggy API responses.

  Pluggy list endpoints return a paginated map:

      %{results: [items...], page: 1, total_pages: 3, total: 150}

  This module provides three consumption patterns:

    * `results/1` — extract the `:results` list from a single page
    * `all_pages/2` — lazy `Stream` of all items across every page
    * `with_cursor/2` — current page results + a cursor to the next page

  All functions accept `{:ok, body}` or `{:error, reason}` tuples and
  propagate errors unchanged.

  ## Req plugin

  `attach/2` adds a response step to a `Req.Request` that automatically
  unwraps paginated responses in one of the three modes above.
  """

  alias Pluggy.Error
  require Logger
  require IEx

  @typedoc "A paginated API response body."
  @type paginated :: %{
          results: list(),
          page: pos_integer(),
          total_pages: non_neg_integer(),
          total: non_neg_integer()
        }

  @typedoc "A function that fetches a specific page number."
  @type fetcher :: (pos_integer() -> {:ok, paginated()} | {:error, Error.t()})

  @doc false
  defguard is_paginated(body)
           when is_map_key(body, :results) and
                  is_map_key(body, :page) and
                  is_map_key(body, :total_pages)

  @doc """
  Extracts the `:results` list from a paginated response.

  Returns the body unchanged when it is not a paginated map.

  ## Examples

      iex> Pluggy.Unwrap.results({:ok, %{results: [1, 2], page: 1, total_pages: 1, total: 2}})
      {:ok, [1, 2]}

      iex> Pluggy.Unwrap.results({:ok, %{id: "single"}})
      {:ok, %{id: "single"}}

      iex> Pluggy.Unwrap.results({:error, %Pluggy.Error{code: 500, message: "boom"}})
      {:error, %Pluggy.Error{code: 500, message: "boom"}}
  """
  @spec results({:ok, map()} | {:error, term()}) :: {:ok, list() | term()} | {:error, term()}
  def results({:ok, body}) when is_paginated(body), do: {:ok, body.results}
  def results({:ok, _body} = ok), do: ok
  def results({:error, _} = error), do: error

  @doc """
  Returns the response as-is, logging a warning when a paginated response
  has more pages available.

  ## Examples

      iex> Pluggy.Unwrap.result({:ok, %{id: "single"}})
      {:ok, %{id: "single"}}

      iex> Pluggy.Unwrap.result({:error, %Pluggy.Error{code: 500, message: "boom"}})
      {:error, %Pluggy.Error{code: 500, message: "boom"}}
  """
  @spec result({:ok, term()} | {:error, term()}) :: {:ok, term()} | {:error, term()}
  def result({:ok, body} = ok) when is_paginated(body) do
    if body.total_pages > body.page do
      Logger.warning(
        "Pluggy response has more pages (page #{body.page} of #{body.total_pages}). " <>
          "Use Unwrap.all_pages/2 to fetch all pages."
      )
    end

    ok
  end

  def result({:ok, _body} = ok), do: ok
  def result({:error, _} = error), do: error

  @doc """
  Unwraps a response tuple, returning the value on success or raising on error.

  ## Examples

      iex> Pluggy.Unwrap.result!({:ok, %{id: "single"}})
      %{id: "single"}
  """
  @spec result!({:ok, term()} | {:error, term()}) :: term()
  def result!(response) do
    case result(response) do
      {:ok, value} -> value
      {:error, %Error{} = error} -> raise RuntimeError, "Pluggy API error: #{error.message} (code: #{error.code})"
    end
  end

  # -- Req plugin --------------------------------------------------------

  @doc """
  Attaches an unwrap response step to a `Req.Request`.

  The step transforms paginated response bodies according to the given mode.
  Non-paginated responses (e.g. single-resource GETs) pass through unchanged.

  ## Modes

    * `:results` — replaces the body with the `:results` list

  ## Usage

      req = Pluggy.Unwrap.attach(req, :results)

      # Now paginated responses return just the items list:
      {:ok, %Req.Response{body: items}} = Req.request(req, url: "/transactions", ...)
  """
  @spec attach(Req.Request.t(), :results) :: Req.Request.t()
  def attach(%Req.Request{} = req, mode) when mode in [:results] do
    req
    |> Req.Request.register_options([:pluggy_unwrap_mode])
    |> Req.Request.merge_options(pluggy_unwrap_mode: mode)
    |> Req.Request.append_response_steps(pluggy_unwrap: &unwrap_step/1)
  end

  defp unwrap_step({req, %Req.Response{status: status, body: body} = response})
       when status in 200..299 do
    IEx.pry()
    case apply_mode(req.options[:pluggy_unwrap_mode], body) do
      {:ok, unwrapped} -> {req, %{response | body: unwrapped}}
      _ -> {req, response}
    end
  end

  defp unwrap_step({req, response}), do: {req, response}

  defp apply_mode(:results, body), do: results({:ok, body})
end
