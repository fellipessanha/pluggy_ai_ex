defmodule Pluggy.AccountsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Accounts
  alias Pluggy.HTTP

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns accounts for an item" do
      client = build_client()

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}} =
               Accounts.list(client, "item-uuid-001")
    end

    test "accepts an item map instead of a string id" do
      client = build_client()
      item = %{id: "item-uuid-001", name: "My Bank"}

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}} =
               Accounts.list(client, item)
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Accounts.list!(client, "item-uuid-001")
    end
  end

  describe "get/2" do
    test "returns an account by id" do
      client = build_client()

      assert {:ok, %{id: "account-uuid-001", balance: 1234.56}} =
               Accounts.get(client, "account-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: "account-uuid-001"} = Accounts.get!(client, "account-uuid-001")
    end
  end

  describe "statements/2" do
    test "returns statements for an account" do
      client = build_client()

      assert {:ok, %{results: [%{id: "stmt-uuid-001"}]}} =
               Accounts.statements(client, "account-uuid-001")
    end
  end

  describe "statements!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Accounts.statements!(client, "account-uuid-001")
    end
  end

  describe "list_with_cursor/3" do
    test "returns results with nil cursor when on last page" do
      client = build_client()

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}, nil} =
               Accounts.list_with_cursor(client, "item-uuid-001")
    end

    test "accepts an item map instead of a string id" do
      client = build_client()
      item = %{id: "item-uuid-001", name: "My Bank"}

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}, nil} =
               Accounts.list_with_cursor(client, item)
    end

    test "returns results with cursor when more pages exist" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/accounts"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(
              200,
              JSON.encode!(%{
                "results" => [%{"id" => "account-uuid-001"}],
                "total" => 2,
                "totalPages" => 3,
                "page" => 1
              })
            )
        end
      end

      {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug])

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}, %HTTP.Cursor{}} =
               Accounts.list_with_cursor(client, "item-uuid-001")
    end
  end
end
