defmodule NxAudio.IO.Errors.FailedToExecuteBackend do
  @moduledoc """
  Error raised when an audio file cannot be parsed using a backend tooling.
  """
  @moduledoc section: :io
  use Splode.Error, fields: [:backend, :reason], class: :io

  @type t() :: Splode.Error.t()

  def message(%{backend: backend, reason: reason}) do
    "Failed to parse audio file using the backend '#{backend}': #{inspect(reason)}"
  end
end
