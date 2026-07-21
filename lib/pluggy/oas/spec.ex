defmodule Pluggy.OAS.Spec do
  @moduledoc false
  # Access to the OpenAPI 3 spec: the config-driven path, the file read, and a few
  # shared helpers. Centralized so the compile-time codegen modules
  # (`Pluggy.OAS.Schema`, `Pluggy.OAS.ResponseKeys`, `Pluggy.OAS.Operation`,
  # `Pluggy.OAS.Codegen`) share one loader.

  @doc """
  Compile-time path to the OAS spec.

  Config-driven (`:pluggy_ai, :oas_spec_path`); defaults to the vendored copy in
  `priv/oas3.json` for consuming apps that don't override it.
  """
  @spec_path Application.compile_env(
               :pluggy_ai,
               :oas_spec_path,
               Application.app_dir(:pluggy_ai, "priv/oas3.json")
             )

  @spec path() :: Path.t()
  def path, do: @spec_path

  @doc "Reads and decodes the OAS spec. Raises if it's missing or malformed."
  @spec load!() :: map()
  def load!, do: path() |> File.read!() |> JSON.decode!()

  @doc "The `components.schemas` map from a decoded spec (`%{}` if absent)."
  @spec schemas(map()) :: map()
  def schemas(%{} = doc), do: get_in(doc, ["components", "schemas"]) || %{}

  @doc false
  # Recursively snake_cases string map keys (for display in generated docs). Keys
  # stay strings — this is doc text, not decoded data, so there's no reason to
  # mint atoms. Shared by `Pluggy.OAS.Schema` and `Pluggy.OAS.Codegen`.
  @spec deep_snake(term()) :: term()
  def deep_snake(%{} = map), do: Map.new(map, fn {k, v} -> {snake_key(k), deep_snake(v)} end)
  def deep_snake(list) when is_list(list), do: Enum.map(list, &deep_snake/1)
  def deep_snake(other), do: other

  defp snake_key(k) when is_binary(k), do: Macro.underscore(k)
  defp snake_key(k), do: k
end
