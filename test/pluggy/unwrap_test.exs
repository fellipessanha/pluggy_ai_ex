defmodule Pluggy.UnwrapTest do
  use ExUnit.Case, async: true

  alias Pluggy.Error
  alias Pluggy.Unwrap

  describe "results/1" do
    test "extracts items from a paginated response" do
      response = {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 1, total: 2}}
      assert {:ok, [%{id: "a"}, %{id: "b"}]} = Unwrap.results(response)
    end

    test "handles empty results" do
      response = {:ok, %{results: [], page: 1, total_pages: 0, total: 0}}
      assert {:ok, []} = Unwrap.results(response)
    end

    test "passes through non-paginated response unchanged" do
      response = {:ok, %{id: "single-item", name: "test"}}
      assert {:ok, %{id: "single-item", name: "test"}} = Unwrap.results(response)
    end

    test "passes through error tuples" do
      error = {:error, %Pluggy.Error{code: 500, message: "Server error"}}
      assert ^error = Unwrap.results(error)
    end
  end

  describe "all_pages/2" do
  end

  describe "with_cursor/2" do
  end

  describe "attach/2 with :results" do
    @mock_plug {Pluggy.Test.MockPlug, []}

    defp build_client do
      {:ok, client} =
        Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

      client
    end

    test "unwraps paginated response to just the results list" do
      client = build_client()
      client = %{client | req: Unwrap.attach(client.req, :results)}

      assert {:ok, [%{id: "account-uuid-001"}]} =
               Pluggy.Accounts.list(client, "item-uuid-001")
    end

    test "passes through non-paginated response unchanged" do
      client = build_client()
      client = %{client | req: Unwrap.attach(client.req, :results)}

      assert {:ok, %{id: "account-uuid-001", balance: 1234.56}} =
               Pluggy.Accounts.get(client, "account-uuid-001")
    end

    test "passes through response with results but no pagination keys" do
      client = build_client()
      client = %{client | req: Unwrap.attach(client.req, :results)}

      assert {:ok, %{results: [%{id: "stmt-uuid-001"}]}} =
               Pluggy.Accounts.statements(client, "account-uuid-001")
    end
  end

  test "raises on error tuple" do
    error = %Error{code: 400, message: "Bad Request"}

    assert_raise RuntimeError, ~r/Pluggy API error/, fn ->
      Unwrap.result!({:error, error})
    end
  end
end
