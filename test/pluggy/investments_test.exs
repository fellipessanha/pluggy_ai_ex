defmodule Pluggy.InvestmentsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Investments
  alias Pluggy.HTTP

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns investments for an item" do
      client = build_client()

      assert {:ok, %{results: [%{id: "inv-uuid-001"}]}} =
               Investments.list(client, "item-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Investments.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns an investment by id" do
      client = build_client()

      assert {:ok, %{id: "inv-uuid-001", balance: 5000.0}} =
               Investments.get(client, "inv-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "inv-uuid-001"} = Investments.get!(client, "inv-uuid-001")
    end
  end

  describe "transactions/2" do
    test "returns transactions for an investment" do
      client = build_client()

      assert {:ok, %{results: [%{id: "inv-txn-uuid-001"}]}} =
               Investments.transactions(client, "inv-uuid-001")
    end
  end

  describe "transactions!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Investments.transactions!(client, "inv-uuid-001")
    end
  end

  describe "list_with_cursor/3" do
    test "returns results with nil cursor when on last page" do
      client = build_client()

      assert {:ok, %{results: [%{id: "inv-uuid-001"}]}, nil} =
               Investments.list_with_cursor(client, "item-uuid-001")
    end

    test "returns results with cursor when more pages exist" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/investments"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(
              200,
              JSON.encode!(%{
                "results" => [%{"id" => "inv-uuid-001"}],
                "total" => 2,
                "totalPages" => 3,
                "page" => 1
              })
            )
        end
      end

      {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug])

      assert {:ok, %{results: [%{id: "inv-uuid-001"}]}, %HTTP.Cursor{}} =
               Investments.list_with_cursor(client, "item-uuid-001")
    end
  end
end
