defmodule Pluggy.SmartTransfersTest do
  use ExUnit.Case, async: true

  alias Pluggy.SmartTransfers

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list_preauthorizations/2" do
    test "returns a list of preauthorizations" do
      client = build_client()

      assert {:ok, %{results: [%{id: "preauth-uuid-001"}]}} =
               SmartTransfers.list_preauthorizations(client)
    end
  end

  describe "list_preauthorizations!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = SmartTransfers.list_preauthorizations!(client)
    end
  end

  describe "create_preauthorization/2" do
    test "creates and returns a preauthorization" do
      client = build_client()

      assert {:ok, %{id: "preauth-uuid-001", status: "ACTIVE"}} =
               SmartTransfers.create_preauthorization(client, %{amount: 100.0})
    end
  end

  describe "create_preauthorization!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "preauth-uuid-001"} = SmartTransfers.create_preauthorization!(client, %{})
    end
  end

  describe "get_preauthorization/2" do
    test "returns a preauthorization by id" do
      client = build_client()

      assert {:ok, %{id: "preauth-uuid-001", status: "ACTIVE"}} =
               SmartTransfers.get_preauthorization(client, "preauth-uuid-001")
    end
  end

  describe "get_preauthorization!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "preauth-uuid-001"} =
               SmartTransfers.get_preauthorization!(client, "preauth-uuid-001")
    end
  end

  describe "list_preauthorization_payments/2" do
    test "returns payments for a preauthorization by string id" do
      client = build_client()

      assert {:ok, %{results: [%{id: "st-payment-uuid-001"}]}} =
               SmartTransfers.list_preauthorization_payments(client, "preauth-uuid-001")
    end

    test "accepts a preauthorization map instead of a string id" do
      client = build_client()
      preauth = %{id: "preauth-uuid-001", status: "ACTIVE"}

      assert {:ok, %{results: [%{id: "st-payment-uuid-001"}]}} =
               SmartTransfers.list_preauthorization_payments(client, preauth)
    end
  end

  describe "list_preauthorization_payments!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{results: [_]} =
               SmartTransfers.list_preauthorization_payments!(client, "preauth-uuid-001")
    end
  end

  describe "create_preauthorization_payment/3" do
    test "creates and returns a payment for a preauthorization by string id" do
      client = build_client()

      assert {:ok, %{id: "st-payment-uuid-001", status: "COMPLETED"}} =
               SmartTransfers.create_preauthorization_payment(client, "preauth-uuid-001", %{
                 amount: 50.0
               })
    end

    test "accepts a preauthorization map instead of a string id" do
      client = build_client()
      preauth = %{id: "preauth-uuid-001", status: "ACTIVE"}

      assert {:ok, %{id: "st-payment-uuid-001"}} =
               SmartTransfers.create_preauthorization_payment(client, preauth, %{amount: 50.0})
    end
  end

  describe "create_preauthorization_payment!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "st-payment-uuid-001"} =
               SmartTransfers.create_preauthorization_payment!(client, "preauth-uuid-001", %{})
    end
  end

  describe "create_payment/2" do
    test "creates and returns a payment" do
      client = build_client()

      assert {:ok, %{id: "st-payment-uuid-001", status: "COMPLETED", amount: 100.0}} =
               SmartTransfers.create_payment(client, %{amount: 100.0})
    end
  end

  describe "create_payment!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "st-payment-uuid-001"} = SmartTransfers.create_payment!(client, %{})
    end
  end

  describe "get_payment/2" do
    test "returns a payment by id" do
      client = build_client()

      assert {:ok, %{id: "st-payment-uuid-001", status: "COMPLETED"}} =
               SmartTransfers.get_payment(client, "st-payment-uuid-001")
    end
  end

  describe "get_payment!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "st-payment-uuid-001"} =
               SmartTransfers.get_payment!(client, "st-payment-uuid-001")
    end
  end
end
