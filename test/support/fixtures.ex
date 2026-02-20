defmodule Pluggy.Test.Fixtures do
  @moduledoc false

  # All fixtures use camelCase string keys to match the real Pluggy API responses.
  # The snake_case conversion happens in the Req response pipeline (Client.snake_keys_step).

  # --- Auth ---

  def auth_success do
    %{"apiKey" => "test-api-key-abc123"}
  end

  def auth_invalid do
    %{"code" => 403, "message" => "Invalid credentials"}
  end

  # --- Connect Token ---

  def connect_token do
    %{"accessToken" => "connect-token-xyz789"}
  end

  # --- Items ---

  def item do
    %{
      "id" => "item-uuid-001",
      "connector" => %{"id" => 201, "name" => "Test Bank"},
      "status" => "UPDATED",
      "executionStatus" => "SUCCESS",
      "createdAt" => "2025-01-01T00:00:00.000Z",
      "updatedAt" => "2025-01-01T01:00:00.000Z"
    }
  end

  # --- Accounts ---

  def accounts do
    %{
      "results" => [account()],
      "total" => 1,
      "totalPages" => 1,
      "page" => 1
    }
  end

  def account do
    %{
      "id" => "account-uuid-001",
      "itemId" => "item-uuid-001",
      "type" => "BANK",
      "subtype" => "CHECKING_ACCOUNT",
      "name" => "Conta Corrente",
      "balance" => 1234.56,
      "currencyCode" => "BRL"
    }
  end

  # --- Transactions ---

  def transactions do
    %{
      "results" => [transaction()],
      "total" => 1,
      "totalPages" => 1,
      "page" => 1
    }
  end

  def transaction do
    %{
      "id" => "txn-uuid-001",
      "accountId" => "account-uuid-001",
      "description" => "PIX Transfer",
      "amount" => -150.0,
      "currencyCode" => "BRL",
      "date" => "2025-01-15T00:00:00.000Z",
      "type" => "DEBIT",
      "category" => %{"id" => "cat-001", "description" => "Transfers"}
    }
  end

  # --- Investments ---

  def investments do
    %{
      "results" => [investment()],
      "total" => 1,
      "totalPages" => 1,
      "page" => 1
    }
  end

  def investment do
    %{
      "id" => "inv-uuid-001",
      "itemId" => "item-uuid-001",
      "name" => "CDB Test",
      "type" => "FIXED_INCOME",
      "balance" => 5000.0,
      "currencyCode" => "BRL"
    }
  end

  # --- Identity ---

  def identity do
    %{
      "id" => "identity-uuid-001",
      "itemId" => "item-uuid-001",
      "fullName" => "Test User",
      "document" => "123.456.789-00",
      "documentType" => "CPF",
      "birthDate" => "1990-01-01T00:00:00.000Z"
    }
  end

  # --- Loans ---

  def loans do
    %{
      "results" => [loan()],
      "total" => 1,
      "totalPages" => 1,
      "page" => 1
    }
  end

  def loan do
    %{
      "id" => "loan-uuid-001",
      "itemId" => "item-uuid-001",
      "contractNumber" => "ABC-123",
      "type" => "PERSONAL_LOAN",
      "totalAmount" => 10000.0,
      "currencyCode" => "BRL"
    }
  end
end
