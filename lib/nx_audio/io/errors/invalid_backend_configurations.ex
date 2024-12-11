defmodule NxAudio.IO.Errors.InvalidBackendConfigurations do
  @moduledoc """
  Error when a invalid configuration is provided to a backend tool.
  """
  @moduledoc section: [:io, :errors]
  use Splode.Error, fields: [:message], class: :invalid

  @type t() :: Splode.Error.t()
end
