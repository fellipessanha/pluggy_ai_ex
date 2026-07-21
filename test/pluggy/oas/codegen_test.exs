defmodule Pluggy.OAS.CodegenTest do
  use ExUnit.Case, async: true

  alias Pluggy.OAS.{Codegen, Operation, Spec}

  describe "operation_doc/1" do
    test "documents each parameter and renders a return example" do
      [op | _] =
        Spec.load!()
        |> Operation.operations()
        |> Enum.filter(&(&1.method == :get and &1.path == "/accounts/{id}"))

      doc = Codegen.operation_doc(op)
      assert doc =~ "## Parameters"
      assert doc =~ "`client`"
      assert doc =~ "`id`"
      assert doc =~ "## Returns"
      assert doc =~ "Pluggy.Schemas.Account.t()"
    end
  end
end
