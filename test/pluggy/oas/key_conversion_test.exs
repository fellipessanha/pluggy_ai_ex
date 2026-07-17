defmodule Pluggy.OAS.KeyConversionTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.KeyConversion

  describe "key_as_atom/1" do
    test "maps known keys to snake_case atoms" do
      assert KeyConversion.key_as_atom("itemId") == :item_id
      assert KeyConversion.key_as_atom("apiKey") == :api_key
      assert KeyConversion.key_as_atom("id") == :id
      assert KeyConversion.key_as_atom("transferNumber") == :transfer_number
    end

    test "returns unknown keys unchanged as strings" do
      assert KeyConversion.key_as_atom("totallyUnknownKeyXYZ") == "totallyUnknownKeyXYZ"
    end
  end

  describe "key_as_atom!/1" do
    test "maps known keys to snake_case atoms" do
      assert KeyConversion.key_as_atom!("itemId") == :item_id
      assert KeyConversion.key_as_atom!("id") == :id
    end

    test "raises on an unknown key" do
      assert_raise ArgumentError, fn -> KeyConversion.key_as_atom!("totallyUnknownKeyXYZ") end
    end
  end
end
