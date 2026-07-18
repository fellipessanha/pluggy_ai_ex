defmodule Pluggy.EndpointsTest do
  use ExUnit.Case, async: true

  alias Pluggy.KeyTransform

  # Echoes the request method/path/query back so we can assert the generator
  # built the right URL, verb, and params for every operation. Answers /auth so
  # the client can authenticate.
  defmodule EchoPlug do
    @behaviour Plug
    import Plug.Conn

    @impl true
    def init(opts), do: opts

    @impl true
    def call(%{method: "POST", request_path: "/auth"} = conn, _opts),
      do: send_json(conn, %{"apiKey" => "test-key"})

    def call(conn, _opts) do
      send_json(conn, %{
        "method" => conn.method,
        "path" => conn.request_path,
        "query" => conn.query_string
      })
    end

    defp send_json(conn, body) do
      conn |> put_resp_content_type("application/json") |> send_resp(200, JSON.encode!(body))
    end
  end

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp echo_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: {EchoPlug, []}])

    client
  end

  defp mock_client do
    {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])
    client
  end

  describe "generated endpoint functions" do
    setup do: {:ok, client: echo_client()}

    for op <- Pluggy.Endpoints.operations() do
      # Unquote only primitives/literals into each test — never the whole op map.
      method = op.method |> to_string() |> String.upcase()
      expected_path = Regex.replace(~r/\{\w+\}/, op.path, "PP")

      stub_args =
        List.duplicate("PP", length(op.path_params)) ++
          List.duplicate("QQ", length(op.required_query)) ++
          if(op.body?, do: [%{}], else: [])

      req_keys = Enum.map(op.required_query, &KeyTransform.to_camel_string(&1.key))

      test "#{method} #{op.path} -> #{inspect(op.module)}.#{op.fun}", %{client: client} do
        args = [client | unquote(Macro.escape(stub_args))]
        assert {:ok, body} = apply(unquote(op.module), unquote(op.fun), args)
        assert body["method"] == unquote(method)
        assert body["path"] == unquote(expected_path)

        for key <- unquote(req_keys) do
          assert body["query"] =~ "#{key}=QQ", "expected #{key} in #{inspect(body["query"])}"
        end
      end
    end
  end

  describe "id extractors" do
    test "an endpoint accepts a struct/map in place of a uuid id" do
      client = echo_client()
      assert {:ok, body} = Pluggy.Account.list(client, %{id: "map-id"})
      assert body["query"] =~ "itemId=map-id"
    end

    test "the extractor is a public helper" do
      assert Pluggy.Transaction.account_id(%{id: "x"}) == "x"
      assert Pluggy.Transaction.account_id("x") == "x"
    end
  end

  describe "against the mock API" do
    test "list returns the fixture body" do
      client = mock_client()

      assert {:ok, %{results: [%{id: "account-uuid-001"}]}} =
               Pluggy.Account.list(client, "item-1")
    end

    test "bang variant unwraps" do
      client = mock_client()
      assert %{id: "item-uuid-001"} = Pluggy.Items.get!(client, "item-1")
    end

    test "list_with_cursor returns a cursor tuple" do
      client = mock_client()

      assert {:ok, %{results: [_ | _]}, cursor} =
               Pluggy.Transaction.transactions_list_with_cursor(client, "acc-1")

      assert cursor == nil or match?(%Pluggy.HTTP.Cursor{}, cursor)
    end
  end
end
