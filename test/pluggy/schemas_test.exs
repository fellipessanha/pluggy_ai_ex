defmodule Pluggy.SchemasTest do
  use ExUnit.Case, async: true

  describe "object schemas" do
    test "generate a struct with snake_case fields" do
      account = %Pluggy.Schemas.Account{}
      fields = account |> Map.from_struct() |> Map.keys()
      assert :item_id in fields
      assert :currency_code in fields
    end

    test "accept a decoded (snake_cased) response map" do
      account = struct(Pluggy.Schemas.Account, %{id: "abc", item_id: "def"})
      assert account.id == "abc"
      assert account.item_id == "def"
    end
  end

  describe "enum schemas" do
    test "expose values/0 and have no struct" do
      values = Pluggy.Schemas.WebhookEventType.values()
      assert is_list(values)
      refute Enum.empty?(values)
      refute function_exported?(Pluggy.Schemas.WebhookEventType, :__struct__, 0)
    end
  end

  describe "composed schemas" do
    test "compile as doc-only (no struct, no values)" do
      Code.ensure_loaded(Pluggy.Schemas.PaymentRequestRecipient)
      refute function_exported?(Pluggy.Schemas.PaymentRequestRecipient, :__struct__, 0)
      refute function_exported?(Pluggy.Schemas.PaymentRequestRecipient, :values, 0)
    end
  end

  describe "moduledocs" do
    test "render the example as a populated struct literal" do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Pluggy.Schemas.Transaction)
      assert doc =~ "## Example"
      assert doc =~ "%Pluggy.Schemas.Transaction{"
      assert doc =~ "currency_code: \"BRL\""
      assert doc =~ "provider_id: nil"
    end
  end
end
