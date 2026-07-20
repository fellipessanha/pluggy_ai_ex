defmodule Pluggy.OAS.SpecTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.Spec

  describe "response_key_strings/1" do
    setup do
      {:ok, keys: Spec.response_key_strings(Spec.load!())}
    end

    test "returns a non-empty list of camelCase strings", %{keys: keys} do
      assert is_list(keys)
      assert keys != []
      assert Enum.all?(keys, &is_binary/1)
    end

    test "includes known keys, incl. one reached via $ref recursion", %{keys: keys} do
      # transferNumber lives in BankData, reached via Account.bankData -> $ref
      for k <- ["id", "itemId", "results", "next", "apiKey", "currencyCode", "transferNumber"] do
        assert k in keys, "expected #{inspect(k)} in extracted keys"
      end
    end

    test "returns [] for a doc with no response schemas" do
      assert Spec.response_key_strings(%{"paths" => %{}}) == []
    end
  end

  describe "struct_fields/1" do
    test "returns sorted, deduped snake_case atoms from properties" do
      schema = %{"properties" => %{"itemId" => %{}, "currencyCode" => %{}, "id" => %{}}}
      assert Spec.struct_fields(schema) == [:currency_code, :id, :item_id]
    end

    test "returns [] when there are no properties" do
      assert Spec.struct_fields(%{"enum" => ["A"]}) == []
    end
  end

  describe "struct_field_types/1" do
    test "maps OAS types to nilable Elixir types, sorted by field" do
      schema = %{
        "properties" => %{
          "itemId" => %{"type" => "string"},
          "balance" => %{"type" => "number"},
          "active" => %{"type" => "boolean"},
          "tags" => %{"type" => "array"},
          "meta" => %{"$ref" => "#/components/schemas/Meta"},
          "birthDate" => %{"type" => ["string", "null"]}
        }
      }

      rendered =
        schema
        |> Spec.struct_field_types()
        |> Enum.map(fn {field, ast} -> {field, Macro.to_string(ast)} end)

      assert rendered == [
               {:active, "boolean() | nil"},
               {:balance, "number() | nil"},
               {:birth_date, "String.t() | nil"},
               {:item_id, "String.t() | nil"},
               {:meta, "term()"},
               {:tags, "list() | nil"}
             ]
    end

    test "returns [] when there are no properties" do
      assert Spec.struct_field_types(%{"enum" => ["A"]}) == []
    end
  end

  describe "enum_values/1" do
    test "returns the enum list" do
      assert Spec.enum_values(%{"enum" => ["A", "B"]}) == ["A", "B"]
    end

    test "returns [] when not an enum" do
      assert Spec.enum_values(%{"properties" => %{}}) == []
    end
  end

  describe "schema_moduledoc/2" do
    test "includes description, example, and enum sections when present" do
      doc =
        Spec.schema_moduledoc("Thing", %{
          "description" => "A thing",
          "example" => %{"a" => 1},
          "enum" => ["X", "Y"]
        })

      assert doc =~ "A thing"
      assert doc =~ "## Example"
      assert doc =~ "## Allowed values"
      assert doc =~ "`\"X\"`"
    end

    test "renders an object example as a struct literal with snake_case fields" do
      doc =
        Spec.schema_moduledoc("Thing", %{
          "properties" => %{"itemId" => %{}, "bankData" => %{}},
          "example" => %{"itemId" => "abc", "bankData" => %{"transferNumber" => "1"}}
        })

      assert doc =~ "%Pluggy.Schemas.Thing{"
      assert doc =~ "item_id: \"abc\""
      # absent field defaults to nil
      assert doc =~ "bank_data: %{\"transfer_number\" => \"1\"}"
    end

    test "nested example keys are snake_case strings, not atoms" do
      doc =
        Spec.schema_moduledoc("Thing", %{
          "properties" => %{"metadata" => %{}},
          "example" => %{
            "metadata" => %{"someBrandNewNestedKey12345" => %{"anotherFreshKey67890" => 1}}
          }
        })

      # nested map value rendered with snake_case string keys (display only)...
      assert doc =~ "\"some_brand_new_nested_key12345\" => %{\"another_fresh_key67890\" => 1}"

      # ...and those keys were never interned as atoms (the BEAM atom table never GCs)
      assert_raise ArgumentError, fn ->
        String.to_existing_atom("some_brand_new_nested_key12345")
      end
    end

    test "falls back to a generic line and omits absent sections" do
      doc = Spec.schema_moduledoc("Thing", %{})
      assert doc =~ "`Thing` schema"
      refute doc =~ "## Example"
      refute doc =~ "## Allowed values"
    end
  end

  describe "tag_module/1" do
    test "PascalCases multi-word tags and normalizes acronyms" do
      assert Spec.tag_module("Account") == "Account"
      assert Spec.tag_module("Boleto Management") == "BoletoManagement"
      assert Spec.tag_module("Smart Transfer") == "SmartTransfer"
      assert Spec.tag_module("Automatic PIX") == "AutomaticPix"
    end
  end

  describe "operations/1" do
    setup do: {:ok, ops: Spec.operations(Spec.load!())}

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
    setup do: {:ok, ops: Spec.operations(Spec.load!())}

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
    setup do: {:ok, entries: Spec.endpoints(Spec.load!())}

    test "collapses the v1/v2 transactions list into one :family entry", %{entries: entries} do
      family =
        Enum.find(entries, &(&1[:kind] == :family and &1.module == Pluggy.Transaction))

      assert family.fun == :list
      assert family.default == :v2
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

  describe "operation_doc/1" do
    test "documents each parameter and renders a return example" do
      [op | _] =
        Spec.operations(Spec.load!())
        |> Enum.filter(&(&1.method == :get and &1.path == "/accounts/{id}"))

      doc = Spec.operation_doc(op)
      assert doc =~ "## Parameters"
      assert doc =~ "`client`"
      assert doc =~ "`id`"
      assert doc =~ "## Returns"
      assert doc =~ "Pluggy.Schemas.Account.t()"
    end
  end
end
