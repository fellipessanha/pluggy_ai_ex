defmodule Pluggy.Payments.IntentsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Payments.Intents

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "create/2" do
    test "creates a payment intent" do
      client = build_client()

      assert {:ok, %{id: "intent-uuid-001", status: "CREATED"}} =
               Intents.create(client, %{paymentRequestId: "request-uuid-001"})
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "intent-uuid-001"} =
               Intents.create!(client, %{paymentRequestId: "request-uuid-001"})
    end
  end

  describe "list/2" do
    test "returns payment intents" do
      client = build_client()

      assert {:ok, %{results: [%{id: "intent-uuid-001"}]}} = Intents.list(client)
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Intents.list!(client)
    end
  end

  describe "get/2" do
    test "returns a payment intent by id" do
      client = build_client()

      assert {:ok, %{id: "intent-uuid-001", status: "CREATED"}} =
               Intents.get(client, "intent-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "intent-uuid-001"} = Intents.get!(client, "intent-uuid-001")
    end
  end
end
