defmodule Pluggy.SessionTest do
  use ExUnit.Case, async: true

  alias Pluggy.Session

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "new/1" do
    test "creates session with client" do
      client = build_client()
      session = Session.new(client)

      assert %Session{} = session
      assert session.client == client
      assert session.connect_token == nil
      assert session.item == nil
      assert session.item_id == nil
      assert session.connect_token_opts == []
    end
  end

  describe "new/2" do
    test "stores connect token options" do
      client = build_client()
      session = Session.new(client, webhook_url: "https://example.com/hook")

      assert session.connect_token_opts == [webhook_url: "https://example.com/hook"]
    end
  end

  describe "connect_token/1" do
    test "fetches and caches token" do
      client = build_client()
      session = Session.new(client)

      assert {:ok, "connect-token-xyz789", updated_session} = Session.connect_token(session)
      assert updated_session.connect_token == "connect-token-xyz789"
    end

    test "returns cached token without new request" do
      client = build_client()
      session = %{Session.new(client) | connect_token: "cached-token"}

      assert {:ok, "cached-token", ^session} = Session.connect_token(session)
    end
  end

  describe "refresh_connect_token/1" do
    test "fetches new token even when cached" do
      client = build_client()
      session = %{Session.new(client) | connect_token: "old-token"}

      assert {:ok, "connect-token-xyz789", updated} = Session.refresh_connect_token(session)
      assert updated.connect_token == "connect-token-xyz789"
    end
  end

  describe "with_item/2" do
    test "sets item and extracts id from atom key" do
      client = build_client()
      session = Session.new(client)
      item = %{id: "item-123", status: "UPDATED"}

      updated = Session.with_item(session, item)
      assert updated.item == item
      assert updated.item_id == "item-123"
    end

    test "extracts id from string key" do
      client = build_client()
      session = Session.new(client)
      item = %{"id" => "item-456"}

      updated = Session.with_item(session, item)
      assert updated.item_id == "item-456"
    end

    test "extracts id from item_id key" do
      client = build_client()
      session = Session.new(client)
      item = %{item_id: "item-789"}

      updated = Session.with_item(session, item)
      assert updated.item_id == "item-789"
    end

    test "extracts id from camelCase itemId key" do
      client = build_client()
      session = Session.new(client)
      item = %{"itemId" => "item-abc"}

      updated = Session.with_item(session, item)
      assert updated.item_id == "item-abc"
    end
  end

  describe "client/1" do
    test "returns the underlying client" do
      client = build_client()
      session = Session.new(client)

      assert Session.client(session) == client
    end
  end

  describe "resource accessors with no item" do
    test "accounts returns :no_item" do
      session = Session.new(build_client())
      assert {:error, :no_item} = Session.accounts(session)
    end

    test "transactions returns :no_item" do
      session = Session.new(build_client())
      assert {:error, :no_item} = Session.transactions(session, "any-account-id")
    end

    test "investments returns :no_item" do
      session = Session.new(build_client())
      assert {:error, :no_item} = Session.investments(session)
    end

    test "identity returns :no_item" do
      session = Session.new(build_client())
      assert {:error, :no_item} = Session.identity(session)
    end

    test "loans returns :no_item" do
      session = Session.new(build_client())
      assert {:error, :no_item} = Session.loans(session)
    end
  end

  describe "resource accessors with item" do
    setup do
      client = build_client()
      session = Session.new(client) |> Session.with_item(%{id: "item-uuid-001"})
      %{session: session}
    end

    test "accounts fetches from API", %{session: session} do
      assert {:ok, %{results: [%{id: "account-uuid-001"}]}} = Session.accounts(session)
    end

    test "transactions fetches from API", %{session: session} do
      assert {:ok, %{results: [%{id: "txn-uuid-001"}]}} =
               Session.transactions(session, "account-uuid-001")
    end

    test "investments fetches from API", %{session: session} do
      assert {:ok, %{results: [%{id: "inv-uuid-001"}]}} = Session.investments(session)
    end

    test "identity fetches from API", %{session: session} do
      assert {:ok, %{id: "identity-uuid-001"}} = Session.identity(session)
    end

    test "loans fetches from API", %{session: session} do
      assert {:ok, %{results: [%{id: "loan-uuid-001"}]}} = Session.loans(session)
    end
  end
end
