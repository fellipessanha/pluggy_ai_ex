defmodule Pluggy.Error do
  @moduledoc """
  Represents an error returned by the Pluggy API or a transport-level failure.

  ## Fields

    * `:code` - HTTP status code (integer) or `:transport` for connection errors
    * `:message` - Human-readable error message
    * `:code_description` - Optional machine-readable error code from the API
    * `:data` - Optional additional error data from the API
  """

  @type t :: %__MODULE__{
          code: integer() | :transport,
          message: String.t(),
          code_description: String.t() | nil,
          data: map() | nil
        }

  defstruct [:code, :message, :code_description, :data]

  @doc """
  Builds an error from an API response body (already snake_cased by the pipeline).

  ## Examples

      iex> Pluggy.Error.from_response(%{code: 401, message: "Unauthorized"})
      %Pluggy.Error{code: 401, message: "Unauthorized"}

      iex> Pluggy.Error.from_response(%{code: 400, message: "Bad Request", code_description: "VALIDATION_ERROR", data: %{field: "amount"}})
      %Pluggy.Error{code: 400, message: "Bad Request", code_description: "VALIDATION_ERROR", data: %{field: "amount"}}
  """
  @spec from_response(map()) :: t()
  def from_response(%{} = response) do
    %__MODULE__{
      code: response[:code],
      message: response[:message],
      code_description: response[:code_description],
      data: response[:data]
    }
  end

  @doc """
  Builds an error for transport-level failures (timeout, connection refused, etc.).

  ## Examples

      iex> Pluggy.Error.transport(:timeout)
      %Pluggy.Error{code: :transport, message: "timeout"}
  """
  @spec transport(atom() | String.t()) :: t()
  def transport(reason) when is_atom(reason) do
    %__MODULE__{code: :transport, message: Atom.to_string(reason)}
  end

  def transport(reason) when is_binary(reason) do
    %__MODULE__{code: :transport, message: reason}
  end
end

defimpl Inspect, for: Pluggy.Error do
  import Inspect.Algebra

  def inspect(%Pluggy.Error{} = error, opts) do
    fields =
      [
        code: error.code,
        message: error.message
      ]
      |> maybe_add(:code_description, error.code_description)
      |> maybe_add(:data, error.data)

    concat(["#Pluggy.Error<", to_doc(fields, opts), ">"])
  end

  defp maybe_add(fields, _key, nil), do: fields
  defp maybe_add(fields, key, value), do: fields ++ [{key, value}]
end
