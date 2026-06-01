defmodule Pluggy.MerchantsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Merchants

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns merchants" do
      client = build_client()

      assert {:ok, %{results: [%{id: "merchant-uuid-001"}]}} = Merchants.list(client)
    end

    test "accepts cnpjs filter option" do
      client = build_client()

      assert {:ok, %{results: [%{id: "merchant-uuid-001"}]}} =
               Merchants.list(client, cnpjs: ["12345678901234"])
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Merchants.list!(client)
    end
  end
end
