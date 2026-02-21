defmodule Pluggy.TransactionsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Transactions

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns transactions for an account" do
      client = build_client()

      assert {:ok, %{results: [%{id: "txn-uuid-001"}]}} =
               Transactions.list(client, "account-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Transactions.list!(client, "account-uuid-001")
    end
  end

  describe "get/2" do
    test "returns a transaction by id" do
      client = build_client()

      assert {:ok, %{id: "txn-uuid-001", amount: -150.0}} =
               Transactions.get(client, "txn-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "txn-uuid-001"} = Transactions.get!(client, "txn-uuid-001")
    end
  end

  describe "update/3" do
    test "updates a transaction" do
      client = build_client()

      assert {:ok, %{id: "txn-uuid-001"}} =
               Transactions.update(client, "txn-uuid-001", %{category_id: "cat-002"})
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "txn-uuid-001"} =
               Transactions.update!(client, "txn-uuid-001", %{category_id: "cat-002"})
    end
  end
end
