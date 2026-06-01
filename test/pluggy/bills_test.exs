defmodule Pluggy.BillsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Bills

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/3" do
    test "returns bills for an account" do
      client = build_client()

      assert {:ok, %{results: [%{id: "bill-uuid-001"}]}} =
               Bills.list(client, "account-uuid-001")
    end

    test "accepts an account map instead of a string id" do
      client = build_client()
      account = %{id: "account-uuid-001", name: "My Account"}

      assert {:ok, %{results: [%{id: "bill-uuid-001"}]}} =
               Bills.list(client, account)
    end
  end

  describe "list!/3" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Bills.list!(client, "account-uuid-001")
    end
  end

  describe "get/2" do
    test "returns a bill by id" do
      client = build_client()

      assert {:ok, %{id: "bill-uuid-001", account_id: "account-uuid-001"}} =
               Bills.get(client, "bill-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "bill-uuid-001"} = Bills.get!(client, "bill-uuid-001")
    end
  end
end
