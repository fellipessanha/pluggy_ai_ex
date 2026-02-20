defmodule Pluggy.HTTPTest do
  use ExUnit.Case, async: true

  alias Pluggy.{Client, HTTP, Error}

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client(opts \\ []) do
    plug = Keyword.get(opts, :plug, @mock_plug)

    {:ok, client} =
      Client.new("test_id", "test_secret", req_options: [plug: plug])

    client
  end

  describe "get/3" do
    test "returns parsed body on success" do
      client = build_client()
      assert {:ok, body} = HTTP.get(client, "/accounts/account-uuid-001")
      assert %{id: "account-uuid-001"} = body
    end

    test "returns error for API error responses" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          _ ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(
              400,
              JSON.encode!(%{
                "code" => 400,
                "message" => "Bad Request"
              })
            )
        end
      end

      client = build_client(plug: plug)
      assert {:error, %Error{code: 400, message: "Bad Request"}} = HTTP.get(client, "/anything")
    end

    test "returns error on 404" do
      client = build_client()
      assert {:error, %Error{}} = HTTP.get(client, "/nonexistent")
    end
  end

  describe "post/3" do
    test "returns parsed body on success" do
      client = build_client()
      assert {:ok, body} = HTTP.post(client, "/connect_token", json: %{})
      assert %{access_token: "connect-token-xyz789"} = body
    end

    test "converts snake_case body keys to camelCase" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"POST", "/items"} ->
            {:ok, raw, conn} = Plug.Conn.read_body(conn)
            decoded = JSON.decode!(raw)

            # Verify keys were converted to camelCase
            assert Map.has_key?(decoded, "connectorId")
            assert Map.has_key?(decoded, "webhookUrl")
            refute Map.has_key?(decoded, "connector_id")

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "new-item"}))

          _ ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(404, JSON.encode!(%{"message" => "not found"}))
        end
      end

      client = build_client(plug: plug)

      assert {:ok, _} =
               HTTP.post(client, "/items",
                 json: %{connector_id: 201, webhook_url: "https://example.com/hook"}
               )
    end
  end

  describe "get/3 query param conversion" do
    test "converts snake_case params to camelCase" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"GET", "/accounts"} ->
            query = Plug.Conn.fetch_query_params(conn).query_params

            # Verify params were converted to camelCase
            assert Map.has_key?(query, "itemId")
            assert Map.has_key?(query, "pageSize")
            refute Map.has_key?(query, "item_id")

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"results" => [], "total" => 0}))

          _ ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(404, JSON.encode!(%{"message" => "not found"}))
        end
      end

      client = build_client(plug: plug)
      assert {:ok, _} = HTTP.get(client, "/accounts", params: [item_id: "abc", page_size: 20])
    end
  end

  describe "delete/3" do
    test "returns ok on success" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "k"}))

          {"DELETE", "/items/" <> _id} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "deleted"}))

          _ ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(404, JSON.encode!(%{"message" => "not found"}))
        end
      end

      client = build_client(plug: plug)
      assert {:ok, _} = HTTP.delete(client, "/items/some-id")
    end
  end

  describe "unwrap!/1" do
    test "returns value from ok tuple" do
      assert :value == HTTP.unwrap!({:ok, :value})
    end

    test "raises on error tuple" do
      error = %Error{code: 400, message: "Bad Request"}

      assert_raise RuntimeError, ~r/Pluggy API error/, fn ->
        HTTP.unwrap!({:error, error})
      end
    end
  end
end
