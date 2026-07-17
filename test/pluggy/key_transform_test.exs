defmodule Pluggy.KeyTransformTest do
  use ExUnit.Case, async: true

  alias Pluggy.KeyTransform

  describe "to_snake/1" do
    test "converts camelCase string keys to snake_case atoms" do
      assert %{item_id: "abc"} = KeyTransform.to_snake(%{"itemId" => "abc"})
    end

    test "handles single-word keys" do
      assert %{id: 1} = KeyTransform.to_snake(%{"id" => 1})
    end

    test "converts nested maps recursively" do
      input = %{"bankData" => %{"transferNumber" => 1, "closingBalance" => "001"}}

      assert %{bank_data: %{transfer_number: 1, closing_balance: "001"}} =
               KeyTransform.to_snake(input)
    end

    test "leaves keys unknown to the OpenAPI spec as strings" do
      assert %{"notAPluggyKey" => 1} == KeyTransform.to_snake(%{"notAPluggyKey" => 1})
    end

    test "converts lists of maps" do
      input = [%{"itemId" => "a"}, %{"itemId" => "b"}]
      assert [%{item_id: "a"}, %{item_id: "b"}] = KeyTransform.to_snake(input)
    end

    test "handles lists nested inside maps" do
      input = %{"results" => [%{"itemId" => "x"}, %{"itemId" => "y"}]}

      assert %{results: [%{item_id: "x"}, %{item_id: "y"}]} =
               KeyTransform.to_snake(input)
    end

    test "passes through non-map non-list values" do
      assert "hello" == KeyTransform.to_snake("hello")
      assert 42 == KeyTransform.to_snake(42)
      assert nil == KeyTransform.to_snake(nil)
      assert true == KeyTransform.to_snake(true)
    end

    test "handles empty map" do
      assert %{} == KeyTransform.to_snake(%{})
    end

    test "handles empty list" do
      assert [] == KeyTransform.to_snake([])
    end
  end

  describe "to_camel/1" do
    test "converts snake_case atom keys to camelCase strings" do
      assert %{"itemId" => "abc"} = KeyTransform.to_camel(%{item_id: "abc"})
    end

    test "handles single-word keys" do
      assert %{"id" => 1} = KeyTransform.to_camel(%{id: 1})
    end

    test "converts nested maps recursively" do
      input = %{payment_data: %{ref_number: 1}}

      assert %{"paymentData" => %{"refNumber" => 1}} =
               KeyTransform.to_camel(input)
    end

    test "converts lists of maps" do
      input = [%{item_id: "a"}, %{item_id: "b"}]
      assert [%{"itemId" => "a"}, %{"itemId" => "b"}] = KeyTransform.to_camel(input)
    end

    test "passes through non-map non-list values" do
      assert "hello" == KeyTransform.to_camel("hello")
      assert 42 == KeyTransform.to_camel(42)
    end

    test "handles empty map" do
      assert %{} == KeyTransform.to_camel(%{})
    end
  end

  describe "to_camel_string/1" do
    test "converts snake_case atom" do
      assert "itemId" == KeyTransform.to_camel_string(:item_id)
    end

    test "converts snake_case string" do
      assert "pageSize" == KeyTransform.to_camel_string("page_size")
    end

    test "returns single-word unchanged" do
      assert "id" == KeyTransform.to_camel_string(:id)
      assert "name" == KeyTransform.to_camel_string("name")
    end

    test "handles multi-segment keys" do
      assert "clientPaymentId" == KeyTransform.to_camel_string(:client_payment_id)
    end
  end
end
