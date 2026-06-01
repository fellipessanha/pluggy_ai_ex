defmodule Pluggy.Payments.CustomersTest do
  use ExUnit.Case, async: true

  alias Pluggy.Payments.Customers

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns a paginated list of payment customers" do
      client = build_client()

      assert {:ok, %{results: [%{id: "customer-uuid-001"}], total: 1, total_pages: 1, page: 1}} =
               Customers.list(client)
    end

    test "accepts optional query params" do
      client = build_client()

      assert {:ok, %{results: [_]}} = Customers.list(client, name: "Test")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Customers.list!(client)
    end
  end

  describe "create/2" do
    test "creates a payment customer" do
      client = build_client()

      assert {:ok, %{id: "customer-uuid-001", name: "Test Customer"}} =
               Customers.create(client, %{name: "Test Customer", taxNumber: "12345678901"})
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "customer-uuid-001"} =
               Customers.create!(client, %{name: "Test Customer", taxNumber: "12345678901"})
    end
  end

  describe "get/2" do
    test "returns a payment customer by id" do
      client = build_client()

      assert {:ok, %{id: "customer-uuid-001", name: "Test Customer"}} =
               Customers.get(client, "customer-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "customer-uuid-001"} = Customers.get!(client, "customer-uuid-001")
    end
  end

  describe "update/3" do
    test "updates a payment customer" do
      client = build_client()

      assert {:ok, %{id: "customer-uuid-001"}} =
               Customers.update(client, "customer-uuid-001", %{name: "Updated Name"})
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "customer-uuid-001"} =
               Customers.update!(client, "customer-uuid-001", %{name: "Updated Name"})
    end
  end

  describe "delete/2" do
    test "deletes a payment customer and returns ok nil" do
      client = build_client()
      assert {:ok, nil} = Customers.delete(client, "customer-uuid-001")
    end
  end

  describe "delete!/2" do
    test "returns unwrapped nil" do
      client = build_client()
      assert nil == Customers.delete!(client, "customer-uuid-001")
    end
  end
end
