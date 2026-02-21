defmodule Pluggy.IdentityTest do
  use ExUnit.Case, async: true

  alias Pluggy.Identity

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns identity data for an item" do
      client = build_client()

      assert {:ok, %{id: "identity-uuid-001", full_name: "Test User"}} =
               Identity.list(client, "item-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "identity-uuid-001"} = Identity.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns identity data by id" do
      client = build_client()

      assert {:ok, %{id: "identity-uuid-001", full_name: "Test User"}} =
               Identity.get(client, "identity-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "identity-uuid-001"} = Identity.get!(client, "identity-uuid-001")
    end
  end
end
