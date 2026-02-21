defmodule Pluggy.LoansTest do
  use ExUnit.Case, async: true

  alias Pluggy.Loans

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns loans for an item" do
      client = build_client()

      assert {:ok, %{results: [%{id: "loan-uuid-001"}]}} =
               Loans.list(client, "item-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Loans.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns a loan by id" do
      client = build_client()

      assert {:ok, %{id: "loan-uuid-001", total_amount: 10000.0}} =
               Loans.get(client, "loan-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "loan-uuid-001"} = Loans.get!(client, "loan-uuid-001")
    end
  end
end
