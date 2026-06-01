defmodule Pluggy.Test.MockPlug do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  alias Pluggy.Test.Fixtures

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    body = if body != "", do: JSON.decode!(body), else: %{}

    handle(conn, conn.method, conn.request_path, body)
  end

  # --- Auth ---

  defp handle(conn, "POST", "/auth", %{"clientId" => "test_id", "clientSecret" => "test_secret"}) do
    send_json(conn, 200, Fixtures.auth_success())
  end

  defp handle(conn, "POST", "/auth", _body) do
    send_json(conn, 403, Fixtures.auth_invalid())
  end

  # --- Connect Token ---

  defp handle(conn, "POST", "/connect_token", _body) do
    send_json(conn, 200, Fixtures.connect_token())
  end

  # --- Connectors ---

  defp handle(conn, "GET", "/connectors", _body) do
    send_json(conn, 200, Fixtures.connectors())
  end

  defp handle(conn, "GET", "/connectors/" <> id, _body) do
    case String.split(id, "/") do
      [_id, "validate"] -> send_json(conn, 200, Fixtures.connector_validation())
      [_id] -> send_json(conn, 200, Fixtures.connector())
    end
  end

  defp handle(conn, "POST", "/connectors/" <> _rest, _body) do
    send_json(conn, 200, Fixtures.connector_validation())
  end

  # --- Items ---

  defp handle(conn, "POST", "/items", _body) do
    send_json(conn, 200, Fixtures.item())
  end

  defp handle(conn, "POST", "/items/" <> _rest, _body) do
    send_json(conn, 200, Fixtures.item())
  end

  defp handle(conn, "GET", "/items/" <> _id, _body) do
    send_json(conn, 200, Fixtures.item())
  end

  defp handle(conn, "PATCH", "/items/" <> _id, _body) do
    send_json(conn, 200, Fixtures.item())
  end

  defp handle(conn, "DELETE", "/items/" <> _id, _body) do
    send_json(conn, 200, Fixtures.item())
  end

  # --- Accounts ---

  defp handle(conn, "GET", "/accounts", _body) do
    send_json(conn, 200, Fixtures.accounts())
  end

  defp handle(conn, "GET", "/accounts/" <> rest, _body) do
    case String.split(rest, "/") do
      [_id, "statements"] -> send_json(conn, 200, Fixtures.account_statements())
      [_id] -> send_json(conn, 200, Fixtures.account())
    end
  end

  # --- Transactions ---

  defp handle(conn, "GET", "/transactions", _body) do
    send_json(conn, 200, Fixtures.transactions())
  end

  defp handle(conn, "GET", "/transactions/" <> _id, _body) do
    send_json(conn, 200, Fixtures.transaction())
  end

  defp handle(conn, "PATCH", "/transactions/" <> _id, _body) do
    send_json(conn, 200, Fixtures.transaction())
  end

  # --- Investments ---

  defp handle(conn, "GET", "/investments", _body) do
    send_json(conn, 200, Fixtures.investments())
  end

  defp handle(conn, "GET", "/investments/" <> rest, _body) do
    case String.split(rest, "/") do
      [_id, "transactions"] -> send_json(conn, 200, Fixtures.investment_transactions())
      [_id] -> send_json(conn, 200, Fixtures.investment())
    end
  end

  # --- Identity ---

  defp handle(conn, "GET", "/identity", _body) do
    send_json(conn, 200, Fixtures.identity())
  end

  defp handle(conn, "GET", "/identity/" <> _id, _body) do
    send_json(conn, 200, Fixtures.identity())
  end

  # --- Loans ---

  defp handle(conn, "GET", "/loans", _body) do
    send_json(conn, 200, Fixtures.loans())
  end

  defp handle(conn, "GET", "/loans/" <> _id, _body) do
    send_json(conn, 200, Fixtures.loan())
  end

  # --- Payment Requests ---

  defp handle(conn, "GET", "/payments/requests", _body) do
    send_json(conn, 200, Fixtures.payment_requests())
  end

  defp handle(conn, "POST", "/payments/requests/automatic-pix", _body) do
    send_json(conn, 200, Fixtures.payment_request())
  end

  defp handle(conn, "POST", "/payments/requests/pix-qr", _body) do
    send_json(conn, 200, Fixtures.payment_request())
  end

  defp handle(conn, "POST", "/payments/requests", _body) do
    send_json(conn, 200, Fixtures.payment_request())
  end

  defp handle(conn, "GET", "/payments/requests/" <> rest, _body) do
    case String.split(rest, "/") do
      [_id, "automatic-pix", "schedules", _payment_id] ->
        send_json(conn, 200, Fixtures.payment_pix_schedule())

      [_id, "automatic-pix", "schedules"] ->
        send_json(conn, 200, Fixtures.payment_pix_schedules())

      [_id, "schedules"] ->
        send_json(conn, 200, Fixtures.payment_schedules())

      [_id] ->
        send_json(conn, 200, Fixtures.payment_request())
    end
  end

  defp handle(conn, "POST", "/payments/requests/" <> rest, _body) do
    case String.split(rest, "/") do
      [_id, "automatic-pix", "cancel"] ->
        send_no_content(conn)

      [_id, "automatic-pix", "schedule"] ->
        send_json(conn, 200, Fixtures.payment_request())

      [_id, "automatic-pix", "schedules", _s, "cancel"] ->
        send_no_content(conn)

      [_id, "automatic-pix", "schedules", _s, "retry"] ->
        send_no_content(conn)

      [_id, "schedules", "cancel"] ->
        send_no_content(conn)

      [_id, "schedules", _sid, "cancel"] ->
        send_no_content(conn)
    end
  end

  defp handle(conn, "PATCH", "/payments/requests/" <> _id, _body) do
    send_json(conn, 200, Fixtures.payment_request())
  end

  defp handle(conn, "DELETE", "/payments/requests/" <> _id, _body) do
    send_no_content(conn)
  end

  # --- Catch-all ---

  defp handle(conn, method, path, _body) do
    send_json(conn, 404, %{"message" => "MockPlug: no handler for #{method} #{path}"})
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, JSON.encode!(body))
  end

  defp send_no_content(conn) do
    send_resp(conn, 204, "")
  end
end
