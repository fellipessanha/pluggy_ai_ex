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

  defp handle(conn, "GET", "/items/" <> _id, _body) do
    send_json(conn, 200, Fixtures.item())
  end

  # --- Accounts ---

  defp handle(conn, "GET", "/accounts", _body) do
    send_json(conn, 200, Fixtures.accounts())
  end

  defp handle(conn, "GET", "/accounts/" <> _id, _body) do
    send_json(conn, 200, Fixtures.account())
  end

  # --- Transactions ---

  defp handle(conn, "GET", "/transactions", _body) do
    send_json(conn, 200, Fixtures.transactions())
  end

  defp handle(conn, "GET", "/transactions/" <> _id, _body) do
    send_json(conn, 200, Fixtures.transaction())
  end

  # --- Investments ---

  defp handle(conn, "GET", "/investments", _body) do
    send_json(conn, 200, Fixtures.investments())
  end

  defp handle(conn, "GET", "/investments/" <> _id, _body) do
    send_json(conn, 200, Fixtures.investment())
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

  # --- Catch-all ---

  defp handle(conn, method, path, _body) do
    send_json(conn, 404, %{"message" => "MockPlug: no handler for #{method} #{path}"})
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, JSON.encode!(body))
  end
end
