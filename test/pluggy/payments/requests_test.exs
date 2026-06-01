defmodule Pluggy.Payments.RequestsTest do
  use ExUnit.Case, async: true

  alias Pluggy.Payments.Requests

  @mock_plug {Pluggy.Test.MockPlug, []}

  defp build_client do
    {:ok, client} =
      Pluggy.Client.new("test_id", "test_secret", req_options: [plug: @mock_plug])

    client
  end

  # --- Base CRUD ---

  describe "list/2" do
    test "returns paginated payment requests" do
      client = build_client()

      assert {:ok, %{results: [%{id: "request-uuid-001"}]}} = Requests.list(client)
    end
  end

  describe "list!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{results: [_]} = Requests.list!(client)
    end
  end

  describe "create/2" do
    test "creates a payment request" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001", status: "CREATED"}} =
               Requests.create(client, %{amount: 100.0})
    end
  end

  describe "create!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} = Requests.create!(client, %{amount: 100.0})
    end
  end

  describe "get/2" do
    test "returns a payment request by id" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001"}} = Requests.get(client, "request-uuid-001")
    end
  end

  describe "get!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} = Requests.get!(client, "request-uuid-001")
    end
  end

  describe "update/3" do
    test "updates a payment request" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001"}} =
               Requests.update(client, "request-uuid-001", %{description: "Updated"})
    end
  end

  describe "update!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} =
               Requests.update!(client, "request-uuid-001", %{description: "Updated"})
    end
  end

  describe "delete/2" do
    test "deletes a payment request" do
      client = build_client()

      assert {:ok, _} = Requests.delete(client, "request-uuid-001")
    end
  end

  describe "delete!/2" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.delete!(client, "request-uuid-001") != :error
    end
  end

  # --- Fixed-path POST variants ---

  describe "create_automatic_pix/2" do
    test "creates an automatic PIX payment request" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001"}} =
               Requests.create_automatic_pix(client, %{amount: 100.0})
    end
  end

  describe "create_automatic_pix!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} =
               Requests.create_automatic_pix!(client, %{amount: 100.0})
    end
  end

  describe "create_pix_qr/2" do
    test "creates a PIX QR code payment request" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001"}} =
               Requests.create_pix_qr(client, %{amount: 50.0})
    end
  end

  describe "create_pix_qr!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} = Requests.create_pix_qr!(client, %{amount: 50.0})
    end
  end

  # --- Automatic PIX sub-resources ---

  describe "cancel_automatic_pix/2" do
    test "cancels automatic PIX and returns ok" do
      client = build_client()

      assert {:ok, _} = Requests.cancel_automatic_pix(client, "request-uuid-001")
    end
  end

  describe "cancel_automatic_pix!/2" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.cancel_automatic_pix!(client, "request-uuid-001") != :error
    end
  end

  describe "schedule_automatic_pix/3" do
    test "schedules automatic PIX and returns the updated request" do
      client = build_client()

      assert {:ok, %{id: "request-uuid-001"}} =
               Requests.schedule_automatic_pix(client, "request-uuid-001", %{date: "2026-01-01"})
    end
  end

  describe "schedule_automatic_pix!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "request-uuid-001"} =
               Requests.schedule_automatic_pix!(client, "request-uuid-001", %{date: "2026-01-01"})
    end
  end

  describe "list_automatic_pix_schedules/2" do
    test "returns paginated automatic PIX schedules" do
      client = build_client()

      assert {:ok, %{results: [%{id: "schedule-uuid-001"}]}} =
               Requests.list_automatic_pix_schedules(client, "request-uuid-001")
    end
  end

  describe "list_automatic_pix_schedules!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{results: [_]} =
               Requests.list_automatic_pix_schedules!(client, "request-uuid-001")
    end
  end

  describe "get_automatic_pix_schedule/3" do
    test "returns a specific automatic PIX schedule" do
      client = build_client()

      assert {:ok, %{id: "schedule-uuid-001"}} =
               Requests.get_automatic_pix_schedule(
                 client,
                 "request-uuid-001",
                 "schedule-uuid-001"
               )
    end
  end

  describe "get_automatic_pix_schedule!/3" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{id: "schedule-uuid-001"} =
               Requests.get_automatic_pix_schedule!(
                 client,
                 "request-uuid-001",
                 "schedule-uuid-001"
               )
    end
  end

  describe "cancel_automatic_pix_schedule/3" do
    test "cancels an automatic PIX schedule and returns ok" do
      client = build_client()

      assert {:ok, _} =
               Requests.cancel_automatic_pix_schedule(
                 client,
                 "request-uuid-001",
                 "schedule-uuid-001"
               )
    end
  end

  describe "cancel_automatic_pix_schedule!/3" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.cancel_automatic_pix_schedule!(
               client,
               "request-uuid-001",
               "schedule-uuid-001"
             ) != :error
    end
  end

  describe "retry_automatic_pix_schedule/3" do
    test "retries an automatic PIX schedule and returns ok" do
      client = build_client()

      assert {:ok, _} =
               Requests.retry_automatic_pix_schedule(
                 client,
                 "request-uuid-001",
                 "schedule-uuid-001"
               )
    end
  end

  describe "retry_automatic_pix_schedule!/3" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.retry_automatic_pix_schedule!(
               client,
               "request-uuid-001",
               "schedule-uuid-001"
             ) != :error
    end
  end

  # --- Regular schedule sub-resources ---

  describe "list_schedules/2" do
    test "returns paginated schedules for a payment request" do
      client = build_client()

      assert {:ok, %{results: [%{id: "schedule-uuid-001"}]}} =
               Requests.list_schedules(client, "request-uuid-001")
    end
  end

  describe "list_schedules!/2" do
    test "returns unwrapped result" do
      client = build_client()

      assert %{results: [_]} = Requests.list_schedules!(client, "request-uuid-001")
    end
  end

  describe "cancel_all_schedules/2" do
    test "cancels all schedules and returns ok" do
      client = build_client()

      assert {:ok, _} = Requests.cancel_all_schedules(client, "request-uuid-001")
    end
  end

  describe "cancel_all_schedules!/2" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.cancel_all_schedules!(client, "request-uuid-001") != :error
    end
  end

  describe "cancel_schedule/3" do
    test "cancels a specific schedule and returns ok" do
      client = build_client()

      assert {:ok, _} =
               Requests.cancel_schedule(client, "request-uuid-001", "schedule-uuid-001")
    end
  end

  describe "cancel_schedule!/3" do
    test "returns unwrapped result on success" do
      client = build_client()

      assert Requests.cancel_schedule!(client, "request-uuid-001", "schedule-uuid-001") != :error
    end
  end
end
