defmodule Pluggy.OAS.ResponseKeysTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.{ResponseKeys, Spec}

  describe "response_key_strings/1" do
    setup do
      {:ok, keys: ResponseKeys.response_key_strings(Spec.load!())}
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

    test "returns [] for a doc with no response schemas" do
      assert ResponseKeys.response_key_strings(%{"paths" => %{}}) == []
    end
  end
end
