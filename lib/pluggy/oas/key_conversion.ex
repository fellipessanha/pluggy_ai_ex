defmodule Pluggy.OAS.KeyConversion do
  @moduledoc """
  Maps Pluggy API response keys (camelCase strings) to snake_case atoms.

  The lookup clauses are generated at compile time — one per key reachable from a
  response body in the OpenAPI spec (see `Pluggy.OAS.Spec`) — so known keys become
  compile-time atom literals with no runtime `String.to_atom`.

      Pluggy.OAS.KeyConversion.key_as_atom("itemId")   #=> :item_id
      Pluggy.OAS.KeyConversion.key_as_atom("unknown")  #=> "unknown"   (passthrough)
      Pluggy.OAS.KeyConversion.key_as_atom!("unknown") #=> ** (ArgumentError)
  """

  @external_resource Pluggy.OAS.Spec.path()
  @key_strings Pluggy.OAS.Spec.load!() |> Pluggy.OAS.ResponseKeys.response_key_strings()

  @doc """
  Converts a known response key string to its snake_case atom. Unknown keys are
  returned unchanged as strings (no runtime atom creation).
  """
  @spec key_as_atom(String.t()) :: atom() | String.t()
  for k <- @key_strings do
    def key_as_atom(unquote(k)), do: unquote(k |> Macro.underscore() |> String.to_atom())
  end

  def key_as_atom(key) when is_binary(key), do: key

  @doc """
  Like `key_as_atom/1`, but raises `ArgumentError` on an unknown key instead of
  passing it through.
  """
  @spec key_as_atom!(String.t()) :: atom()
  for k <- @key_strings do
    def key_as_atom!(unquote(k)), do: unquote(k |> Macro.underscore() |> String.to_atom())
  end

  def key_as_atom!(key) when is_binary(key),
    do: key |> Macro.underscore() |> String.to_existing_atom()
end
