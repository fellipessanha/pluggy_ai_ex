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

  @doc """
  Resolves the API version to use for a versioned endpoint (e.g. the v1/v2
  transactions list).

  Precedence, mirroring `base_url/0`:

    1. the `:api_versions` application config, keyed by `{module, function}` —
       `config :pluggy_ai, :api_versions, %{{Pluggy.Transaction, :list} => :v1}`
    2. the `PLUGGY_<MODULE>_VERSION` environment variable (e.g.
       `PLUGGY_TRANSACTION_VERSION=v1`), validated as `v<n>`
    3. `default` — the newest version, baked in by the generator

  Resolved at call time, so consuming apps can change it via config or env
  without recompiling this library.
  """
  @spec api_version(module(), atom(), atom()) :: atom()
  def api_version(module, fun, default) do
    Application.get_env(:pluggy_ai, :api_versions, %{})[{module, fun}] ||
      env_api_version(module) ||
      default
  end

  defp env_api_version(module) do
    suffix = module |> Module.split() |> List.last() |> String.upcase()

    case System.get_env("PLUGGY_#{suffix}_VERSION") do
      "v" <> _ = value -> if Regex.match?(~r/^v\d+$/, value), do: String.to_atom(value)
      _ -> nil
    end
  end
end
