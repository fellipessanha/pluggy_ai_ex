defmodule Pluggy.UnwrapTest do
  use ExUnit.Case, async: true

  alias Pluggy.Error
  alias Pluggy.HTTP.Cursor
  alias Pluggy.Unwrap

  describe "results/1" do
    test "extracts items from a paginated response" do
      response = {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 1, total: 2}}
      assert [%{id: "a"}, %{id: "b"}] = Unwrap.results(response)
    end

    test "handles empty results" do
      response = {:ok, %{results: [], page: 1, total_pages: 0, total: 0}}
      assert [] = Unwrap.results(response)
    end

    test "passes through non-paginated response unchanged" do
      response = {:ok, %{id: "single-item", name: "test"}}
      assert %{id: "single-item", name: "test"} = Unwrap.results(response)
    end

    test "passes through error tuples" do
      error = {:error, %Pluggy.Error{code: 500, message: "Server error"}}
      assert ^error = Unwrap.results(error)
    end
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

  describe "results/1 with cursor tuples" do
    test "extracts results from cursor tuple" do
      cursor = %Cursor{fetcher: fn _ -> :ok end, page: 2}
      data = %{results: [%{id: "a"}], page: 1, total_pages: 3, total: 3}

      assert [%{id: "a"}] = Unwrap.results({:ok, data, cursor})
    end

    test "extracts results with nil cursor" do
      data = %{results: [%{id: "a"}], page: 1, total_pages: 1, total: 1}

      assert [%{id: "a"}] = Unwrap.results({:ok, data, nil})
    end

    test "passes through non-paginated body from cursor tuple" do
      data = %{id: "single"}

      assert %{id: "single"} = Unwrap.results({:ok, data, nil})
    end
  end

  describe "all_results/1" do
    test "returns items from a single page" do
      result = {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 1, total: 2}, nil}

      assert [%{id: "a"}, %{id: "b"}] = Unwrap.all_results(result)
    end

    test "collects and flattens items across multiple pages" do
      fetcher = fn
        2 -> {:ok, %{results: [%{id: "c"}], page: 2, total_pages: 3, total: 3}}
        3 -> {:ok, %{results: [%{id: "d"}], page: 3, total_pages: 3, total: 3}}
      end

      cursor = %Cursor{fetcher: fetcher, page: 2}

      result =
        {:ok, %{results: [%{id: "a"}, %{id: "b"}], page: 1, total_pages: 3, total: 3}, cursor}

      assert [%{id: "a"}, %{id: "b"}, %{id: "c"}, %{id: "d"}] =
               Unwrap.all_results(result)
    end

    test "returns error tuple on error input" do
      error = {:error, %Error{code: 500, message: "boom"}}

      assert {:error, %Error{code: 500}} = Unwrap.all_results(error)
    end

    test "returns error when a page fetch fails mid-pagination" do
      fetcher = fn 2 -> {:error, %Error{code: 500, message: "boom"}} end
      cursor = %Cursor{fetcher: fetcher, page: 2}

      result =
        {:ok, %{results: [%{id: "a"}], page: 1, total_pages: 2, total: 2}, cursor}

      assert {:error, _} = Unwrap.all_results(result)
    end

    test "returns empty list for empty results" do
      result = {:ok, %{results: [], page: 1, total_pages: 1, total: 0}, nil}

      assert [] = Unwrap.all_results(result)
    end
  end

  test "raises on error tuple" do
    error = %Error{code: 400, message: "Bad Request"}

    assert_raise RuntimeError, ~r/Pluggy API error/, fn ->
      Unwrap.results!({:error, error})
    end
  end
end
