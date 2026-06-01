defmodule Pluggy.CategoriesTest do
  use ExUnit.Case, async: true

  alias Pluggy.Categories

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  describe "list/2" do
    test "returns a list of categories" do
      client = build_client()

      assert {:ok, [%{id: "cat-uuid-001", description: "Food & Dining"}]} =
               Categories.list(client)
    end

    test "accepts opts like parent_id" do
      client = build_client()

      assert {:ok, [%{id: "cat-uuid-001"}]} = Categories.list(client, parent_id: "cat-uuid-001")
    end
  end

  describe "list!/2" do
    test "returns unwrapped list of categories" do
      client = build_client()
      assert [%{id: "cat-uuid-001"}] = Categories.list!(client)
    end
  end

  describe "get/2" do
    test "returns a category by id" do
      client = build_client()

      assert {:ok, %{id: "cat-uuid-001", description: "Food & Dining"}} =
               Categories.get(client, "cat-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped category" do
      client = build_client()
      assert %{id: "cat-uuid-001"} = Categories.get!(client, "cat-uuid-001")
    end
  end

  describe "list_rules/1" do
    test "returns a list of category rules" do
      client = build_client()

      assert {:ok, [%{id: "rule-uuid-001", category_id: "cat-uuid-001"}]} =
               Categories.list_rules(client)
    end
  end

  describe "list_rules!/1" do
    test "returns unwrapped list of category rules" do
      client = build_client()
      assert [%{id: "rule-uuid-001"}] = Categories.list_rules!(client)
    end
  end

  describe "create_rule/2" do
    test "creates a category rule and returns it" do
      client = build_client()

      assert {:ok, %{id: "rule-uuid-001", category_id: "cat-uuid-001"}} =
               Categories.create_rule(client, %{category_id: "cat-uuid-001"})
    end
  end

  describe "create_rule!/2" do
    test "returns unwrapped created category rule" do
      client = build_client()

      assert %{id: "rule-uuid-001"} =
               Categories.create_rule!(client, %{category_id: "cat-uuid-001"})
    end
  end
end
