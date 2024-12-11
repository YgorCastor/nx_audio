defmodule NxAudio.IO.Errors.InvalidMetadata do
  @moduledoc """
  Error when an invalid metadata is returned by a backend tool.
  """
  @moduledoc section: [:io, :errors]
  use Splode.Error, fields: [:reason], class: :invalid

  @type t() :: Splode.Error.t()

  def message(%{reason: reason}) do
    "Failed to parse metadata: #{reason}"
  end
end
