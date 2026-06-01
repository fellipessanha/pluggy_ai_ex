defmodule Pluggy.Payments.RecipientsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Payments.Recipients

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns payment recipients" do
      client = build_client()

      assert {:ok, %{results: [%{id: "recipient-uuid-001"}]}} = Recipients.list(client)
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Recipients.list!(client)
    end
  end

  describe "create/2" do
    test "creates a payment recipient" do
      client = build_client()

      assert {:ok, %{id: "recipient-uuid-001", name: "Test Recipient"}} =
               Recipients.create(client, %{name: "Test Recipient", tax_number: "12345678901"})
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "recipient-uuid-001"} = Recipients.create!(client, %{name: "Test Recipient"})
    end
  end

  describe "get/2" do
    test "returns a payment recipient by id" do
      client = build_client()

      assert {:ok, %{id: "recipient-uuid-001", name: "Test Recipient"}} =
               Recipients.get(client, "recipient-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "recipient-uuid-001"} = Recipients.get!(client, "recipient-uuid-001")
    end
  end

  describe "update/3" do
    test "updates a payment recipient" do
      client = build_client()

      assert {:ok, %{id: "recipient-uuid-001"}} =
               Recipients.update(client, "recipient-uuid-001", %{name: "Updated Name"})
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "recipient-uuid-001"} =
               Recipients.update!(client, "recipient-uuid-001", %{name: "Updated Name"})
    end
  end

  describe "delete/2" do
    test "deletes a payment recipient and returns ok nil" do
      client = build_client()
      assert {:ok, nil} = Recipients.delete(client, "recipient-uuid-001")
    end
  end

  describe "delete!/2" do
    test "returns unwrapped nil on success" do
      client = build_client()
      assert nil == Recipients.delete!(client, "recipient-uuid-001")
    end
  end

  describe "list_institutions/2" do
    test "returns payment recipient institutions" do
      client = build_client()

      assert {:ok, %{results: [%{id: "institution-uuid-001"}]}} =
               Recipients.list_institutions(client)
    end
  end

  describe "list_institutions!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Recipients.list_institutions!(client)
    end
  end

  describe "get_institution/2" do
    test "returns a payment recipient institution by id" do
      client = build_client()

      assert {:ok, %{id: "institution-uuid-001", name: "Test Bank"}} =
               Recipients.get_institution(client, "institution-uuid-001")
    end
  end

  describe "get_institution!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "institution-uuid-001"} =
               Recipients.get_institution!(client, "institution-uuid-001")
    end
  end
end
