defmodule Pluggy.AuthTest do
  use ExUnit.Case, async: true

  alias Pluggy.Auth

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_req(client_id \\ "test_id", client_secret \\ "test_secret") do
    Req.new(base_url: "https://some.api.url/", plug: @mock_plug)
    |> Auth.attach(client_id, client_secret)
  end

  describe "attach/3" do
    test "registers custom options" do
      req = build_req()

      assert req.options[:pluggy_client_id] == "test_id"
      assert req.options[:pluggy_client_secret] == "test_secret"
      assert req.options[:pluggy_auth_retried] == false
      assert req.options[:pluggy_api_key] == nil
    end

    test "prepends auth request step" do
      req = build_req()
      step_names = Enum.map(req.request_steps, fn {name, _} -> name end)
      assert :pluggy_auth in step_names
    end

    test "appends retry response step" do
      req = build_req()
      step_names = Enum.map(req.response_steps, fn {name, _} -> name end)
      assert :pluggy_retry_auth in step_names
    end
  end

  describe "authenticate/1" do
    test "returns api key on valid credentials" do
      req = build_req()
      assert {:ok, "test-api-key-abc123"} = Auth.authenticate(req)
    end

    test "returns error on invalid credentials" do
      req = build_req("bad_id", "bad_secret")
      assert {:error, msg} = Auth.authenticate(req)
      assert msg =~ "403"
    end
  end

  describe "auth request step" do
    test "fetches and caches api key when none present" do
      req = build_req()

      # Run the request through the pipeline — MockPlug handles /auth + the actual request
      assert {:ok, %Req.Response{}} = Req.request(req, url: "/items/some-id", method: :get)
    end

    test "uses cached api key when present" do
      req =
        build_req()
        |> Req.Request.merge_options(pluggy_api_key: "cached-key")

      # Track that /auth was NOT called by using a plug that rejects auth requests
      plug = fn conn ->
        if conn.request_path == "/auth" do
          raise "should not call /auth when key is cached"
        end

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      req = %{req | options: Map.put(req.options, :plug, plug)}
      assert {:ok, %Req.Response{status: 200}} = Req.request(req, url: "/items/x", method: :get)
    end
  end

  describe "retry auth response step" do
    test "retries once on 401 and succeeds" do
      call_count = :counters.new(1, [:atomics])

      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "fresh-key"}))

          _ ->
            count = :counters.get(call_count, 1)
            :counters.add(call_count, 1, 1)

            if count == 0 do
              # First attempt: 401
              conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(401, JSON.encode!(%{"message" => "Unauthorized"}))
            else
              # Retry: success
              conn
              |> Plug.Conn.put_resp_content_type("application/json")
              |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "ok"}))
            end
        end
      end

      req =
        Req.new(base_url: "https://api.pluggy.ai", plug: plug)
        |> Auth.attach("test_id", "test_secret")
        |> Req.Request.merge_options(pluggy_api_key: "stale-key")

      assert {:ok, %Req.Response{status: 200}} = Req.request(req, url: "/items/x", method: :get)
    end

    test "does not retry more than once" do
      plug = fn conn ->
        case {conn.method, conn.request_path} do
          {"POST", "/auth"} ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, JSON.encode!(%{"apiKey" => "fresh-key"}))

          _ ->
            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(401, JSON.encode!(%{"message" => "Unauthorized"}))
        end
      end

      req =
        Req.new(base_url: "https://api.pluggy.ai", plug: plug)
        |> Auth.attach("test_id", "test_secret")
        |> Req.Request.merge_options(pluggy_api_key: "stale-key")

      assert {:ok, %Req.Response{status: 401}} = Req.request(req, url: "/items/x", method: :get)
    end
  end
end
