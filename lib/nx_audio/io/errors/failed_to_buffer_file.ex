defmodule NxAudio.IO.Errors.FailedToBufferFile do
  @moduledoc """
  Error when writing the tensor to a temporary file
  """
  @moduledoc section: [:io, :errors]
  use Splode.Error, fields: [:reason], class: :io

  @type t() :: Splode.Error.t()

  @doc false
  def message(%{reason: reason}) do
    "Failed to buffer file: #{inspect(reason)}"
  end
end
