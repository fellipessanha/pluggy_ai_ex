defmodule Pluggy.OAS.SpecTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.Spec

  describe "load!/0 and schemas/1" do
    test "loads the vendored spec and exposes its components.schemas" do
      doc = Spec.load!()
      assert is_map(doc["paths"])
      assert is_map(Spec.schemas(doc))
      assert Map.has_key?(Spec.schemas(doc), "Account")
    end

    test "schemas/1 defaults to an empty map" do
      assert Spec.schemas(%{}) == %{}
    end
  end

  describe "deep_snake/1" do
    test "recursively snake_cases string map keys, leaving values" do
      assert Spec.deep_snake(%{"itemId" => %{"bankData" => 1}}) ==
               %{"item_id" => %{"bank_data" => 1}}

      assert Spec.deep_snake([%{"fooBar" => "x"}]) == [%{"foo_bar" => "x"}]
    end

    test "passes non-maps through unchanged" do
      assert Spec.deep_snake("x") == "x"
    end
  end
end
