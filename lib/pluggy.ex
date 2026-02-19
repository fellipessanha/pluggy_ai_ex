defmodule Pluggy do
  @moduledoc """
  Top-level module for the Pluggy API client library.

  Provides the base URL configuration for the Pluggy API.
  """

  @default_base_url "https://api.pluggy.ai"

  @doc """
  Returns the base URL for the Pluggy API.

  Reads from the `:pluggy_ai` application config key `:base_url`,
  or the `PLUGGY_BASE_URL` environment variable, falling back to
  `#{@default_base_url}`.
  """
  @spec base_url() :: String.t()
  def base_url do
    Application.get_env(:pluggy_ai, :base_url) ||
      System.get_env("PLUGGY_BASE_URL") ||
      @default_base_url
  end
end
