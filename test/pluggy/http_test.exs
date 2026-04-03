defmodule Pluggy.HTTPTest do
  use ExUnit.Case, async: true

  doctest Pluggy.HTTP

  alias Pluggy.{Client, Error, HTTP}

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

  describe "with_cursor/2" do
    test "returns nil cursor when response is a single page" do
      fetcher = fn 1 ->
        {:ok, %{results: [%{id: "a"}], page: 1, total_pages: 1, total: 1}}
      end

      assert {:ok, %{results: [%{id: "a"}]}, nil} = HTTP.with_cursor(fetcher)
    end

    test "returns cursor with next page when more pages exist" do
      fetcher = fn 1 ->
        {:ok, %{results: [%{id: "a"}], page: 1, total_pages: 3, total: 3}}
      end

      assert {:ok, %{results: [%{id: "a"}]}, %HTTP.Cursor{page: 2}} =
               HTTP.with_cursor(fetcher)
    end

    test "advances through pages with with_cursor/1" do
      fetcher = fn
        1 -> {:ok, %{results: [%{id: "a"}], page: 1, total_pages: 3, total: 3}}
        2 -> {:ok, %{results: [%{id: "b"}], page: 2, total_pages: 3, total: 3}}
        3 -> {:ok, %{results: [%{id: "c"}], page: 3, total_pages: 3, total: 3}}
      end

      assert {:ok, %{results: [%{id: "a"}]}, cursor} = HTTP.with_cursor(fetcher)
      assert %HTTP.Cursor{page: 2} = cursor

      assert {:ok, %{results: [%{id: "b"}]}, cursor} = HTTP.with_cursor(cursor)
      assert %HTTP.Cursor{page: 3} = cursor

      assert {:ok, %{results: [%{id: "c"}]}, nil} = HTTP.with_cursor(cursor)
    end

    test "starts from a custom page number" do
      fetcher = fn
        2 -> {:ok, %{results: [%{id: "b"}], page: 2, total_pages: 3, total: 3}}
        3 -> {:ok, %{results: [%{id: "c"}], page: 3, total_pages: 3, total: 3}}
      end

      assert {:ok, %{results: [%{id: "b"}]}, %HTTP.Cursor{page: 3}} =
               HTTP.with_cursor(fetcher, 2)
    end

    test "propagates errors from the fetcher" do
      error = %Error{code: 500, message: "Internal Server Error"}

      fetcher = fn 1 -> {:error, error} end

      assert {:error, ^error} = HTTP.with_cursor(fetcher)
    end

    test "returns nil cursor for non-paginated response" do
      fetcher = fn 1 -> {:ok, %{id: "single-item"}} end

      assert {:ok, %{id: "single-item"}, nil} = HTTP.with_cursor(fetcher)
    end
  end

  describe "stream_results/1" do
    test "emits a single page when cursor is nil" do
      result = {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 1, total: 2}, nil}

      assert [%{results: [%{id: "a"}, %{id: "b"}]}] = Enum.to_list(HTTP.stream_results(result))
    end

    test "emits one list per page across multiple pages" do
      fetcher = fn
        2 -> {:ok, %{results: [%{id: "c"}], page: 2, total_pages: 3, total: 3}}
        3 -> {:ok, %{results: [%{id: "d"}], page: 3, total_pages: 3, total: 3}}
      end

      cursor = %HTTP.Cursor{fetcher: fetcher, page: 2}

      result =
        {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 3, total: 3}, cursor}

      assert [
               %{results: [%{id: "a"}, %{id: "b"}]},
               %{results: [%{id: "c"}]},
               %{results: [%{id: "d"}]}
             ] = Enum.to_list(HTTP.stream_results(result))
    end

    test "is lazy — does not fetch pages beyond what is consumed" do
      test_pid = self()

      fetcher = fn page ->
        send(test_pid, {:fetched, page})
        {:ok, %{results: [%{id: "page-#{page}"}], page: page, total_pages: 5, total: 5}}
      end

      cursor = %HTTP.Cursor{fetcher: fetcher, page: 2}

      result =
        {:ok, %{results: [%{id: "page-1"}], page: 1, total_pages: 5, total: 5}, cursor}

      result
      |> HTTP.stream_results()
      |> Enum.take(2)

      assert_received {:fetched, 2}
      refute_received {:fetched, 3}
    end

    test "raises on error during pagination" do
      fetcher = fn 2 -> {:error, %Error{code: 500, message: "boom"}} end
      cursor = %HTTP.Cursor{fetcher: fetcher, page: 2}

      result =
        {:ok, %{results: [%{id: "a"}], page: 1, total_pages: 3, total: 3}, cursor}

      stream = HTTP.stream_results(result)

      assert_raise RuntimeError, ~r/pagination error/, fn ->
        Enum.to_list(stream)
      end
    end

    test "emits empty list for empty first page" do
      result = {:ok, %{results: [], page: 1, total_pages: 1, total: 0}, nil}

      assert [%{results: [], page: 1}] = Enum.to_list(HTTP.stream_results(result))
    end

    test "raises on error tuple input" do
      error = {:error, %Error{code: 500, message: "boom"}}

      assert_raise RuntimeError, ~r/Cannot stream/, fn ->
        HTTP.stream_results(error)
      end
    end
  end
end
