defmodule Pluggy.OAS.SpecTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.Spec

  describe "response_key_strings/1" do
    setup do
      {:ok, keys: Spec.response_key_strings(Spec.load!())}
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
      assert Spec.response_key_strings(%{"paths" => %{}}) == []
    end
  end

  describe "struct_fields/1" do
    test "returns sorted, deduped snake_case atoms from properties" do
      schema = %{"properties" => %{"itemId" => %{}, "currencyCode" => %{}, "id" => %{}}}
      assert Spec.struct_fields(schema) == [:currency_code, :id, :item_id]
    end

    test "returns [] when there are no properties" do
      assert Spec.struct_fields(%{"enum" => ["A"]}) == []
    end
  end

  describe "enum_values/1" do
    test "returns the enum list" do
      assert Spec.enum_values(%{"enum" => ["A", "B"]}) == ["A", "B"]
    end

    test "returns [] when not an enum" do
      assert Spec.enum_values(%{"properties" => %{}}) == []
    end
  end

  describe "schema_moduledoc/2" do
    test "includes description, example, and enum sections when present" do
      doc =
        Spec.schema_moduledoc("Thing", %{
          "description" => "A thing",
          "example" => %{"a" => 1},
          "enum" => ["X", "Y"]
        })

      assert doc =~ "A thing"
      assert doc =~ "## Example"
      assert doc =~ "## Allowed values"
      assert doc =~ "`\"X\"`"
    end

    test "renders an object example as a struct literal with snake_case fields" do
      doc =
        Spec.schema_moduledoc("Thing", %{
          "properties" => %{"itemId" => %{}, "bankData" => %{}},
          "example" => %{"itemId" => "abc", "bankData" => %{"transferNumber" => "1"}}
        })

      assert doc =~ "%Pluggy.Schemas.Thing{"
      assert doc =~ "item_id: \"abc\""
      # absent field defaults to nil
      assert doc =~ "bank_data: %{\"transfer_number\" => \"1\"}"
    end

    test "nested example keys are snake_case strings, not atoms" do
      before = :erlang.system_info(:atom_count)

      Spec.schema_moduledoc("Thing", %{
        "properties" => %{"id" => %{}},
        "example" => %{
          "id" => "x",
          "someBrandNewNestedKey12345" => %{"anotherFreshKey67890" => 1}
        }
      })

      # rendering doc text must not mint atoms for arbitrary example keys
      assert :erlang.system_info(:atom_count) == before
    end

    test "falls back to a generic line and omits absent sections" do
      doc = Spec.schema_moduledoc("Thing", %{})
      assert doc =~ "`Thing` schema"
      refute doc =~ "## Example"
      refute doc =~ "## Allowed values"
    end
  end
end
