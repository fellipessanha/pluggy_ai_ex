defmodule Pluggy.KeyTransform do
  @moduledoc false

  @doc """
  Converts a map (or list of maps) from camelCase string keys to snake_case atom keys, recursively.

  ## Examples

      iex> Pluggy.KeyTransform.to_snake(%{"itemId" => "abc", "paymentData" => %{"refNumber" => 1}})
      %{item_id: "abc", payment_data: %{ref_number: 1}}

      iex> Pluggy.KeyTransform.to_snake(%{"id" => 1})
      %{id: 1}

      iex> Pluggy.KeyTransform.to_snake([%{"itemId" => "a"}, %{"itemId" => "b"}])
      [%{item_id: "a"}, %{item_id: "b"}]
  """
  @spec to_snake(term()) :: term()
  def to_snake(%{} = map) do
    Map.new(map, fn {key, value} ->
      new_key =
        key
        |> to_string()
        |> Macro.underscore()
        |> String.to_atom()

      {new_key, to_snake(value)}
    end)
  end

  def to_snake(list) when is_list(list) do
    Enum.map(list, &to_snake/1)
  end

  def to_snake(value), do: value

  @doc """
  Converts a map (or list of maps) from snake_case atom keys to camelCase string keys, recursively.

  ## Examples

      iex> Pluggy.KeyTransform.to_camel(%{item_id: "abc", payment_data: %{ref_number: 1}})
      %{"itemId" => "abc", "paymentData" => %{"refNumber" => 1}}

      iex> Pluggy.KeyTransform.to_camel(%{id: 1})
      %{"id" => 1}
  """
  @spec to_camel(term()) :: term()
  def to_camel(%{} = map) do
    Map.new(map, fn {key, value} ->
      {to_camel_string(key), to_camel(value)}
    end)
  end

  def to_camel(list) when is_list(list) do
    Enum.map(list, &to_camel/1)
  end

  def to_camel(value), do: value

  @doc false
  @spec to_camel_string(atom() | String.t()) :: String.t()
  def to_camel_string(key) when is_atom(key) do
    key |> Atom.to_string() |> to_camel_string()
  end

  def to_camel_string(key) when is_binary(key) do
    case String.split(key, "_") do
      [single] -> single
      [head | tail] -> head <> Enum.map_join(tail, &String.capitalize/1)
    end
  end
end
