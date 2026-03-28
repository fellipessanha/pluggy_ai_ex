defmodule Pluggy.ConnectorsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Connectors

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/1" do
    test "returns connectors" do
      client = build_client()
      assert {:ok, %{results: [%{id: 201, name: "Test Bank"}]}} = Connectors.list(client)
    end
  end

  describe "list/2" do
    test "passes filter options as query params" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/connectors"} ->
            query = Plug.Conn.fetch_query_params(conn).query_params
            assert Map.has_key?(query, "sandbox")

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"results" => [], "total" => 0}))
        end
      end

      {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug])
      assert {:ok, _} = Connectors.list(client, sandbox: true)
    end
  end

  describe "list!/1" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{results: [_]} = Connectors.list!(client)
    end
  end

  describe "get/2" do
    test "returns a connector by id" do
      client = build_client()
      assert {:ok, %{id: 201, name: "Test Bank"}} = Connectors.get(client, 201)
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{id: 201} = Connectors.get!(client, 201)
    end
  end

  describe "list_with_cursor/1" do
    test "returns results with nil cursor when on last page" do
      client = build_client()

      assert {:ok, %{results: [%{id: 201, name: "Test Bank"}]}, nil} =
               Connectors.list_with_cursor(client)
    end

    test "returns results with next page number when more pages exist" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/connectors"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(
              200,
              JSON.encode!(%{
                "results" => [%{"id" => 201, "name" => "Test Bank"}],
                "total" => 2,
                "totalPages" => 3,
                "page" => 1
              })
            )
        end
      end

      {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug])

      assert {:ok, %{results: [%{id: 201, name: "Test Bank"}]}, 2} =
               Connectors.list_with_cursor(client)
    end

    test "returns error on failure" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/connectors"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(500, JSON.encode!(%{"message" => "Internal error"}))
        end
      end

      {:ok, client} =
        Pluggy.Client.new("test_id", "test_secret", req_options: [plug: plug, retry: false])

      assert {:error, _} = Connectors.list_with_cursor(client)
    end
  end

  describe "validate/3" do
    test "validates connector credentials" do
      client = build_client()
      params = %{user: "test", password: "pass"}
      assert {:ok, %{is_valid: true}} = Connectors.validate(client, 201, params)
    end
  end

  describe "validate!/3" do
    test "returns unwrapped result" do
      client = build_client()
      assert %{is_valid: true} = Connectors.validate!(client, 201, %{user: "test"})
    end
  end
end
