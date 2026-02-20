defmodule Pluggy.ItemsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Items

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "create/2" do
    test "creates a new item" do
      client = build_client()
      attrs = %{connector_id: 201, parameters: %{user: "test", password: "pass"}}
      assert {:ok, %{id: "item-uuid-001"}} = Items.create(client, attrs)
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "item-uuid-001"} = Items.create!(client, %{connector_id: 201})
    end
  end

  describe "get/2" do
    test "returns an item" do
      client = build_client()
      assert {:ok, %{id: "item-uuid-001", status: "UPDATED"}} = Items.get(client, "item-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "item-uuid-001"} = Items.get!(client, "item-uuid-001")
    end
  end

  describe "update/3" do
    test "updates an item" do
      client = build_client()
      attrs = %{webhook_url: "https://example.com/hook"}
      assert {:ok, %{id: "item-uuid-001"}} = Items.update(client, "item-uuid-001", attrs)
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "item-uuid-001"} = Items.update!(client, "item-uuid-001", %{})
    end
  end

  describe "delete/2" do
    test "deletes an item" do
      client = build_client()
      assert {:ok, _} = Items.delete(client, "item-uuid-001")
    end
  end

  describe "delete!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert Items.delete!(client, "item-uuid-001")
    end
  end

  describe "send_mfa/3" do
    test "sends MFA response" do
      client = build_client()
      params = %{token: "123456"}
      assert {:ok, %{id: "item-uuid-001"}} = Items.send_mfa(client, "item-uuid-001", params)
    end
  end

  describe "send_mfa!/3" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "item-uuid-001"} = Items.send_mfa!(client, "item-uuid-001", %{token: "123"})
    end
  end

  describe "disable_auto_sync/2" do
    test "disables auto sync" do
      client = build_client()
      assert {:ok, %{id: "item-uuid-001"}} = Items.disable_auto_sync(client, "item-uuid-001")
    end
  end

  describe "disable_auto_sync!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "item-uuid-001"} = Items.disable_auto_sync!(client, "item-uuid-001")
    end
  end
end
