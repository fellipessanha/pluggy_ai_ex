defmodule Pluggy.Payments.Requests do
  @moduledoc """
  Functions for interacting with the Pluggy Payments Requests API.

  A payment request represents a payment initiation request, supporting
  regular PIX, automatic PIX, and PIX QR code flows, along with schedule
  management for recurring payments.
  """

  alias Pluggy.{Client, HTTP}

  @prefix_url "/payments/requests"

  # --- Base CRUD ---

  @doc """
  Lists payment requests.

  ## Options

    * `:page` - Page number for pagination

  ## Examples

      Pluggy.Payments.Requests.list(client)
      Pluggy.Payments.Requests.list(client, page: 2)
  """
  @spec list(Client.t(), keyword()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    HTTP.get(client, @prefix_url, params: opts)
  end

  @spec list!(Client.t(), keyword()) :: term()
  def list!(%Client{} = client, opts \\ []),
    do: HTTP.unwrap_tuple!(list(client, opts))

  @doc """
  Creates a new payment request.

  ## Examples

      Pluggy.Payments.Requests.create(client, %{amount: 100.0, description: "Test"})
  """
  @spec create(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create(%Client{} = client, attrs) do
    HTTP.post(client, @prefix_url, json: attrs)
  end

  @spec create!(Client.t(), map()) :: term()
  def create!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create(client, attrs))

  @doc """
  Gets a payment request by ID.

  ## Examples

      Pluggy.Payments.Requests.get(client, "request-uuid-001")
  """
  @spec get(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def get(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}")
  end

  @spec get!(Client.t(), String.t()) :: term()
  def get!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(get(client, id))

  @doc """
  Updates a payment request.

  ## Examples

      Pluggy.Payments.Requests.update(client, "request-uuid-001", %{description: "Updated"})
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def update(%Client{} = client, id, attrs) do
    HTTP.patch(client, "#{@prefix_url}/#{id}", json: attrs)
  end

  @spec update!(Client.t(), String.t(), map()) :: term()
  def update!(%Client{} = client, id, attrs),
    do: HTTP.unwrap_tuple!(update(client, id, attrs))

  @doc """
  Deletes a payment request.

  ## Examples

      Pluggy.Payments.Requests.delete(client, "request-uuid-001")
  """
  @spec delete(Client.t(), String.t()) :: {:ok, nil} | {:error, Pluggy.Error.t()}
  def delete(%Client{} = client, id) do
    HTTP.delete(client, "#{@prefix_url}/#{id}")
  end

  @spec delete!(Client.t(), String.t()) :: nil
  def delete!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(delete(client, id))

  # --- Fixed-path POST variants ---

  @doc """
  Creates an automatic PIX payment request.

  ## Examples

      Pluggy.Payments.Requests.create_automatic_pix(client, %{amount: 100.0})
  """
  @spec create_automatic_pix(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_automatic_pix(%Client{} = client, attrs) do
    HTTP.post(client, "#{@prefix_url}/automatic-pix", json: attrs)
  end

  @spec create_automatic_pix!(Client.t(), map()) :: term()
  def create_automatic_pix!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_automatic_pix(client, attrs))

  @doc """
  Creates a PIX QR code payment request.

  ## Examples

      Pluggy.Payments.Requests.create_pix_qr(client, %{amount: 50.0})
  """
  @spec create_pix_qr(Client.t(), map()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def create_pix_qr(%Client{} = client, attrs) do
    HTTP.post(client, "#{@prefix_url}/pix-qr", json: attrs)
  end

  @spec create_pix_qr!(Client.t(), map()) :: term()
  def create_pix_qr!(%Client{} = client, attrs),
    do: HTTP.unwrap_tuple!(create_pix_qr(client, attrs))

  # --- Automatic PIX sub-resources ---

  @doc """
  Cancels the automatic PIX for a payment request.

  Returns `{:ok, nil}` on success (HTTP 204).

  ## Examples

      Pluggy.Payments.Requests.cancel_automatic_pix(client, "request-uuid-001")
  """
  @spec cancel_automatic_pix(Client.t(), String.t()) ::
          {:ok, nil} | {:error, Pluggy.Error.t()}
  def cancel_automatic_pix(%Client{} = client, id) do
    HTTP.post(client, "#{@prefix_url}/#{id}/automatic-pix/cancel")
  end

  @spec cancel_automatic_pix!(Client.t(), String.t()) :: nil
  def cancel_automatic_pix!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(cancel_automatic_pix(client, id))

  @doc """
  Schedules an automatic PIX for a payment request.

  ## Examples

      Pluggy.Payments.Requests.schedule_automatic_pix(client, "request-uuid-001", %{date: "2026-01-01"})
  """
  @spec schedule_automatic_pix(Client.t(), String.t(), map()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def schedule_automatic_pix(%Client{} = client, id, attrs) do
    HTTP.post(client, "#{@prefix_url}/#{id}/automatic-pix/schedule", json: attrs)
  end

  @spec schedule_automatic_pix!(Client.t(), String.t(), map()) :: term()
  def schedule_automatic_pix!(%Client{} = client, id, attrs),
    do: HTTP.unwrap_tuple!(schedule_automatic_pix(client, id, attrs))

  @doc """
  Lists automatic PIX schedules for a payment request.

  ## Examples

      Pluggy.Payments.Requests.list_automatic_pix_schedules(client, "request-uuid-001")
  """
  @spec list_automatic_pix_schedules(Client.t(), String.t()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def list_automatic_pix_schedules(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/automatic-pix/schedules")
  end

  @spec list_automatic_pix_schedules!(Client.t(), String.t()) :: term()
  def list_automatic_pix_schedules!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(list_automatic_pix_schedules(client, id))

  @doc """
  Gets a specific automatic PIX schedule for a payment request.

  ## Examples

      Pluggy.Payments.Requests.get_automatic_pix_schedule(client, "request-uuid-001", "schedule-uuid-001")
  """
  @spec get_automatic_pix_schedule(Client.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Pluggy.Error.t()}
  def get_automatic_pix_schedule(%Client{} = client, request_id, payment_id) do
    HTTP.get(client, "#{@prefix_url}/#{request_id}/automatic-pix/schedules/#{payment_id}")
  end

  @spec get_automatic_pix_schedule!(Client.t(), String.t(), String.t()) :: term()
  def get_automatic_pix_schedule!(%Client{} = client, request_id, payment_id),
    do: HTTP.unwrap_tuple!(get_automatic_pix_schedule(client, request_id, payment_id))

  @doc """
  Cancels a specific automatic PIX schedule.

  Returns `{:ok, nil}` on success (HTTP 204).

  ## Examples

      Pluggy.Payments.Requests.cancel_automatic_pix_schedule(client, "request-uuid-001", "schedule-uuid-001")
  """
  @spec cancel_automatic_pix_schedule(Client.t(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Pluggy.Error.t()}
  def cancel_automatic_pix_schedule(%Client{} = client, id, schedule_id) do
    HTTP.post(client, "#{@prefix_url}/#{id}/automatic-pix/schedules/#{schedule_id}/cancel")
  end

  @spec cancel_automatic_pix_schedule!(Client.t(), String.t(), String.t()) :: nil
  def cancel_automatic_pix_schedule!(%Client{} = client, id, schedule_id),
    do: HTTP.unwrap_tuple!(cancel_automatic_pix_schedule(client, id, schedule_id))

  @doc """
  Retries a specific automatic PIX schedule.

  Returns `{:ok, nil}` on success (HTTP 204).

  ## Examples

      Pluggy.Payments.Requests.retry_automatic_pix_schedule(client, "request-uuid-001", "schedule-uuid-001")
  """
  @spec retry_automatic_pix_schedule(Client.t(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Pluggy.Error.t()}
  def retry_automatic_pix_schedule(%Client{} = client, id, schedule_id) do
    HTTP.post(client, "#{@prefix_url}/#{id}/automatic-pix/schedules/#{schedule_id}/retry")
  end

  @spec retry_automatic_pix_schedule!(Client.t(), String.t(), String.t()) :: nil
  def retry_automatic_pix_schedule!(%Client{} = client, id, schedule_id),
    do: HTTP.unwrap_tuple!(retry_automatic_pix_schedule(client, id, schedule_id))

  # --- Regular schedule sub-resources ---

  @doc """
  Lists schedules for a payment request.

  ## Examples

      Pluggy.Payments.Requests.list_schedules(client, "request-uuid-001")
  """
  @spec list_schedules(Client.t(), String.t()) :: {:ok, term()} | {:error, Pluggy.Error.t()}
  def list_schedules(%Client{} = client, id) do
    HTTP.get(client, "#{@prefix_url}/#{id}/schedules")
  end

  @spec list_schedules!(Client.t(), String.t()) :: term()
  def list_schedules!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(list_schedules(client, id))

  @doc """
  Cancels all schedules for a payment request.

  Returns `{:ok, nil}` on success (HTTP 204).

  ## Examples

      Pluggy.Payments.Requests.cancel_all_schedules(client, "request-uuid-001")
  """
  @spec cancel_all_schedules(Client.t(), String.t()) ::
          {:ok, nil} | {:error, Pluggy.Error.t()}
  def cancel_all_schedules(%Client{} = client, id) do
    HTTP.post(client, "#{@prefix_url}/#{id}/schedules/cancel")
  end

  @spec cancel_all_schedules!(Client.t(), String.t()) :: nil
  def cancel_all_schedules!(%Client{} = client, id),
    do: HTTP.unwrap_tuple!(cancel_all_schedules(client, id))

  @doc """
  Cancels a specific schedule for a payment request.

  Returns `{:ok, nil}` on success (HTTP 204).

  ## Examples

      Pluggy.Payments.Requests.cancel_schedule(client, "request-uuid-001", "schedule-uuid-001")
  """
  @spec cancel_schedule(Client.t(), String.t(), String.t()) ::
          {:ok, nil} | {:error, Pluggy.Error.t()}
  def cancel_schedule(%Client{} = client, id, schedule_id) do
    HTTP.post(client, "#{@prefix_url}/#{id}/schedules/#{schedule_id}/cancel")
  end

  @spec cancel_schedule!(Client.t(), String.t(), String.t()) :: nil
  def cancel_schedule!(%Client{} = client, id, schedule_id),
    do: HTTP.unwrap_tuple!(cancel_schedule(client, id, schedule_id))
end
