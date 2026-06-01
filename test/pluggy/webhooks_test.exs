defmodule Pluggy.WebhooksTest do
  use ExUnit.Case, async: true

  alias Pluggy.Webhooks

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/1" do
    test "returns all webhooks" do
      client = build_client()

      assert {:ok, %{results: [%{id: "webhook-uuid-001"}]}} = Webhooks.list(client)
    end
  end

  describe "list!/1" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Webhooks.list!(client)
    end
  end

  describe "create/2" do
    test "creates a new webhook" do
      client = build_client()

      attrs = %{event: "item/created", url: "https://example.com/hook", headers: %{}}

      assert {:ok, %{id: "webhook-uuid-001", event: "item/created"}} =
               Webhooks.create(client, attrs)
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()

      attrs = %{event: "item/created", url: "https://example.com/hook"}

      assert %{id: "webhook-uuid-001"} = Webhooks.create!(client, attrs)
    end
  end

  describe "get/2" do
    test "returns a webhook by id" do
      client = build_client()

      assert {:ok, %{id: "webhook-uuid-001", url: "https://example.com/hook"}} =
               Webhooks.get(client, "webhook-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "webhook-uuid-001"} = Webhooks.get!(client, "webhook-uuid-001")
    end
  end

  describe "update/3" do
    test "updates a webhook" do
      client = build_client()

      assert {:ok, %{id: "webhook-uuid-001"}} =
               Webhooks.update(client, "webhook-uuid-001", %{url: "https://example.com/new-hook"})
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "webhook-uuid-001"} =
               Webhooks.update!(client, "webhook-uuid-001", %{url: "https://example.com/new-hook"})
    end
  end

  describe "delete/2" do
    test "deletes a webhook and returns ok nil" do
      client = build_client()
      assert {:ok, _} = Webhooks.delete(client, "webhook-uuid-001")
    end
  end

  describe "delete!/2" do
    test "returns nil on success" do
      client = build_client()
      assert Webhooks.delete!(client, "webhook-uuid-001")
    end
  end
end
