defmodule Pluggy.OASTest do
  use ExUnit.Case, async: true

  @spec_path Path.expand("../../design-docs/oas3.json", __DIR__)

  describe "Spec.response_key_strings/1" do
    setup do
      keys =
        @spec_path |> File.read!() |> JSON.decode!() |> Pluggy.OAS.Spec.response_key_strings()

      {:ok, keys: keys}
    end

    test "returns a non-empty list of camelCase strings", %{keys: keys} do
      assert is_list(keys)
      assert keys != []
      assert Enum.all?(keys, &is_binary/1)
    end

    test "includes known keys, incl. one reached via $ref recursion", %{keys: keys} do
      # transferNumber lives in BankData, reached via Account.bankData -> $ref
      for k <- ["id", "itemId", "results", "next", "apiKey", "currencyCode", "transferNumber"] do
        assert k in keys, "expected #{inspect(k)} in extracted keys"
      end
    end
  end

  describe "key_as_atom/1" do
    test "maps known keys to snake_case atoms" do
      assert Pluggy.OAS.key_as_atom("itemId") == :item_id
      assert Pluggy.OAS.key_as_atom("apiKey") == :api_key
      assert Pluggy.OAS.key_as_atom("id") == :id
      assert Pluggy.OAS.key_as_atom("transferNumber") == :transfer_number
    end

    test "returns unknown keys unchanged as strings" do
      assert Pluggy.OAS.key_as_atom("totallyUnknownKeyXYZ") == "totallyUnknownKeyXYZ"
    end
  end

  describe "key_as_atom!/1" do
    test "maps known keys to snake_case atoms" do
      assert Pluggy.OAS.key_as_atom!("itemId") == :item_id
      assert Pluggy.OAS.key_as_atom!("id") == :id
    end

    test "raises on an unknown key" do
      assert_raise ArgumentError, fn -> Pluggy.OAS.key_as_atom!("totallyUnknownKeyXYZ") end
    end
  end
end
