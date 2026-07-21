defmodule Pluggy.EndpointsVersionTest do
  # async: false — these tests mutate the global :api_versions app env and the
  # PLUGGY_*_VERSION env var, which the version dispatch reads at call time.
  use ExUnit.Case, async: false

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp client do
    {:ok, client} = Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])
    client
  end

  # v1 fixture is page-shaped (:page); v2 is cursor-shaped (:next).
  defp version_of(%{page: _}), do: :v1
  defp version_of(%{next: _}), do: :v2

  setup do
    on_exit(fn ->
      Application.delete_env(:pluggy_ai, :api_versions)
      System.delete_env("PLUGGY_TRANSACTION_VERSION")
    end)
  end

  test "defaults to the newest version (:v2)" do
    assert {:ok, body} = Pluggy.Transaction.list(client(), "acc-1")
    assert version_of(body) == :v2
  end

  test "app config overrides the default" do
    Application.put_env(:pluggy_ai, :api_versions, %{{Pluggy.Transaction, :list} => :v1})
    assert {:ok, body} = Pluggy.Transaction.list(client(), "acc-1")
    assert version_of(body) == :v1
  end

  test "env var overrides the default" do
    System.put_env("PLUGGY_TRANSACTION_VERSION", "v1")
    assert {:ok, body} = Pluggy.Transaction.list(client(), "acc-1")
    assert version_of(body) == :v1
  end

  test "app config takes precedence over the env var" do
    Application.put_env(:pluggy_ai, :api_versions, %{{Pluggy.Transaction, :list} => :v2})
    System.put_env("PLUGGY_TRANSACTION_VERSION", "v1")
    assert {:ok, body} = Pluggy.Transaction.list(client(), "acc-1")
    assert version_of(body) == :v2
  end

  test "an explicit version: opt beats config" do
    Application.put_env(:pluggy_ai, :api_versions, %{{Pluggy.Transaction, :list} => :v1})
    assert {:ok, body} = Pluggy.Transaction.list(client(), "acc-1", version: :v2)
    assert version_of(body) == :v2
  end
end
