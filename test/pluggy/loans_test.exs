defmodule Pluggy.LoansTest do
  use ExUnit.Case, async: true

  alias Pluggy.Loans
  alias Pluggy.HTTP

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns loans for an item" do
      client = build_client()

      assert {:ok, %{results: [%{id: "loan-uuid-001"}]}} =
               Loans.list(client, "item-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Loans.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns a loan by id" do
      client = build_client()

      assert {:ok, %{id: "loan-uuid-001", total_amount: 10_000.0}} =
               Loans.get(client, "loan-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "loan-uuid-001"} = Loans.get!(client, "loan-uuid-001")
    end
  end

  describe "list_with_cursor/3" do
    test "returns results with nil cursor when on last page" do
      client = build_client()

      assert {:ok, %{results: [%{id: "loan-uuid-001"}]}, nil} =
               Loans.list_with_cursor(client, "item-uuid-001")
    end

    test "returns results with cursor when more pages exist" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/loans"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(
              200,
              JSON.encode!(%{
                "results" => [%{"id" => "loan-uuid-001"}],
                "total" => 2,
                "totalPages" => 3,
                "page" => 1
              })
            )
        end
      end

      {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug])

      assert {:ok, %{results: [%{id: "loan-uuid-001"}]}, %HTTP.Cursor{}} =
               Loans.list_with_cursor(client, "item-uuid-001")
    end
  end
end
