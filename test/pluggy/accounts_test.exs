defmodule Pluggy.AccountsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Accounts

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns accounts for an item" do
      client = build_client()

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}} =
               Accounts.list(client, "item-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Accounts.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns an account by id" do
      client = build_client()

      assert {:ok, %{id: "account-uuid-001", balance: 1234.56}} =
               Accounts.get(client, "account-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "account-uuid-001"} = Accounts.get!(client, "account-uuid-001")
    end
  end

  describe "statements/2" do
    test "returns statements for an account" do
      client = build_client()

      assert {:ok, %{results: [%{id: "stmt-uuid-001"}]}} =
               Accounts.statements(client, "account-uuid-001")
    end
  end

  describe "statements!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Accounts.statements!(client, "account-uuid-001")
    end
  end
end
