defmodule Pluggy.ClientTest do
  use ExUnit.Case, async: true

  alias Pluggy.Client

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client(opts \\ []) do
    plug = Keyword.get(opts, :plug, @mock_plug)

    Client.new("test_id", "test_secret", req_options: [plug: plug])
  end

  describe "new/3" do
    test "creates authenticated client" do
      assert {:ok, %Client{} = client} = build_client()
      assert client.client_id == "test_id"
      assert client.client_secret == "test_secret"
    end

    test "caches the api key after initial auth" do
      {:ok, client} = build_client()
      assert client.req.options[:pluggy_api_key] == "test-api-key-abc123"
    end

    test "returns error on auth failure" do
      result =
        Client.new("bad_id", "bad_secret",
          req_options: [plug: @mock_plug]
        )

      assert {:error, %Pluggy.Error{code: :auth_failed}} = result
    end

    test "accepts custom base_url" do
      {:ok, client} = Client.new("test_id", "test_secret",
        base_url: "https://custom.api.example.com",
        req_options: [plug: @mock_plug]
      )

      assert client.req.options[:base_url] == "https://custom.api.example.com"
    end
  end

  describe "new!/3" do
    test "returns client on success" do
      assert %Client{} = Client.new!("test_id", "test_secret", req_options: [plug: @mock_plug])
    end

    test "raises on auth failure" do
      assert_raise RuntimeError, ~r/Failed to create Pluggy client/, fn ->
        Client.new!("bad_id", "bad_secret", req_options: [plug: @mock_plug])
      end
    end
  end

  describe "connect_token/2" do
    test "returns the access token" do
      {:ok, client} = build_client()
      assert {:ok, "connect-token-xyz789"} = Client.connect_token(client)
    end
  end

  describe "snake_keys response step" do
    test "converts camelCase response keys to snake_case atoms" do
      {:ok, client} = build_client()

      assert {:ok, body} = Pluggy.HTTP.get(client, "/accounts/account-uuid-001")
      assert %{item_id: "item-uuid-001"} = body
      assert %{currency_code: "BRL"} = body
    end

    test "converts nested maps" do
      {:ok, client} = build_client()

      assert {:ok, body} = Pluggy.HTTP.get(client, "/items/item-uuid-001")
      assert %{connector: %{name: "Test Bank"}} = body
    end
  end
end
