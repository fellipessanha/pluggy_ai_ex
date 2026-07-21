defmodule Pluggy.OAS.OperationTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.{Operation, Spec}

  describe "tag_module/1" do
    test "PascalCases multi-word tags and normalizes acronyms" do
      assert Operation.tag_module("Account") == "Account"
      assert Operation.tag_module("Boleto Management") == "BoletoManagement"
      assert Operation.tag_module("Smart Transfer") == "SmartTransfer"
      assert Operation.tag_module("Automatic PIX") == "AutomaticPix"
    end
  end

  describe "operations/1" do
    setup do: {:ok, ops: Operation.operations(Spec.load!())}

    test "normalizes each path+method with a resolved fun and module", %{ops: ops} do
      get = fn method, path -> Enum.find(ops, &(&1.method == method and &1.path == path)) end

      account_get = get.(:get, "/accounts/{id}")
      assert account_get.module == Pluggy.Account
      assert account_get.fun == :get
      assert hd(account_get.path_params).key == :id

      # GET collection -> :list; POST collection -> :create
      assert get.(:get, "/accounts").fun == :list
      assert get.(:post, "/items").fun == :create

      # trailing literal action segment -> its snake_case name
      assert get.(:get, "/accounts/{id}/balance").fun == :balance
      assert get.(:post, "/items/{id}/mfa").fun == :mfa
    end

    test "resolves name collisions within a module via operationId", %{ops: ops} do
      boletos = Enum.filter(ops, &(&1.module == Pluggy.BoletoManagement))
      names = boletos |> Enum.map(& &1.fun) |> Enum.sort()
      # two colliding POST creates fall back to operationId-derived names
      assert :boleto_connection_create in names
      assert :boleto_create in names
      assert length(names) == length(Enum.uniq(names))
    end

    test "flags `\\w+Id` uuid params as extractable and marks required query", %{ops: ops} do
      transactions_list = Enum.find(ops, &(&1.method == :get and &1.path == "/transactions"))
      account_id = Enum.find(transactions_list.required_query, &(&1.name == "accountId"))
      assert account_id.extract? == true
      assert account_id.key == :account_id

      # optional non-uuid params are not extractable
      bill_id = Enum.find(transactions_list.optional_query, &(&1.name == "billId"))
      assert bill_id.extract? == true
    end

    test "maps response shape and reuses schema names", %{ops: ops} do
      account_get = Enum.find(ops, &(&1.method == :get and &1.path == "/accounts/{id}"))
      assert account_get.response_kind == :struct
      assert account_get.response_schema == "Account"
    end
  end

  describe "version detection" do
    setup do: {:ok, ops: Operation.operations(Spec.load!())}

    test "tags each op with a version and a version-stripped family key", %{ops: ops} do
      v1 = Enum.find(ops, &(&1.method == :get and &1.path == "/transactions"))
      v2 = Enum.find(ops, &(&1.method == :get and &1.path == "/v2/transactions"))

      assert v1.version == :v1
      assert v2.version == :v2
      # both strip to the same family key, so they group together
      assert v1.family_key == v2.family_key
      assert v1.family_key == {:get, "/transactions"}
    end
  end

  describe "endpoints/1" do
    setup do: {:ok, entries: Operation.endpoints(Spec.load!())}

    test "collapses the v1/v2 transactions list into one :family entry", %{entries: entries} do
      family =
        Enum.find(entries, &(&1[:kind] == :family and &1.module == Pluggy.Transaction))

      assert family.fun == :list
      assert family.default == :v2
      assert family.base_path == "/transactions"
      assert family.members |> Enum.map(&elem(&1, 0)) |> Enum.sort() == [:v1, :v2]
    end

    test "leaves non-versioned transaction ops as singles", %{entries: entries} do
      singles =
        for %{kind: :single, op: op} <- entries, op.module == Pluggy.Transaction, do: op.fun

      assert :get in singles
      assert :update in singles
    end

    test "does not falsely unify same-named ops on different resources", %{entries: entries} do
      # POST /boletos and POST /boleto-connections both prefer :create but are
      # different resources — they must stay separate singles, not a family.
      boleto_families =
        Enum.filter(entries, &(&1[:kind] == :family and &1.module == Pluggy.BoletoManagement))

      assert boleto_families == []
    end
  end
end
