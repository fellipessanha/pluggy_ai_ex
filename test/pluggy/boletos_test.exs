defmodule Pluggy.BoletosTest do
  use ExUnit.Case, async: true

  alias Pluggy.Boletos

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "create/2" do
    test "creates a boleto and returns it" do
      client = build_client()

      assert {:ok, %{id: "boleto-uuid-001", status: "ACTIVE"}} =
               Boletos.create(client, %{amount: 100.0, due_date: "2024-01-15"})
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "boleto-uuid-001"} = Boletos.create!(client, %{amount: 100.0})
    end
  end

  describe "get/2" do
    test "returns a boleto by id" do
      client = build_client()

      assert {:ok, %{id: "boleto-uuid-001", amount: 100.0}} =
               Boletos.get(client, "boleto-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "boleto-uuid-001"} = Boletos.get!(client, "boleto-uuid-001")
    end
  end

  describe "cancel/2" do
    test "returns {:ok, nil} on success" do
      client = build_client()
      assert {:ok, nil} = Boletos.cancel(client, "boleto-uuid-001")
    end
  end

  describe "cancel!/2" do
    test "returns nil on success" do
      client = build_client()
      assert nil == Boletos.cancel!(client, "boleto-uuid-001")
    end
  end

  describe "create_connection/2" do
    test "creates a boleto connection and returns it" do
      client = build_client()

      assert {:ok, %{id: "boleto-conn-uuid-001", item_id: "item-uuid-001"}} =
               Boletos.create_connection(client, %{
                 boleto_id: "boleto-uuid-001",
                 item_id: "item-uuid-001"
               })
    end
  end

  describe "create_connection!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "boleto-conn-uuid-001"} = Boletos.create_connection!(client, %{})
    end
  end

  describe "create_connection_from_item/2" do
    test "creates a boleto connection from an item and returns it" do
      client = build_client()

      assert {:ok, %{id: "boleto-conn-uuid-001", boleto_id: "boleto-uuid-001"}} =
               Boletos.create_connection_from_item(client, %{item_id: "item-uuid-001"})
    end
  end

  describe "create_connection_from_item!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "boleto-conn-uuid-001"} = Boletos.create_connection_from_item!(client, %{})
    end
  end
end
