defmodule NxAudio.Transforms.Errors.InvalidTransformationConfiguration do
  @moduledoc """
  Error when a invalid configuration is provided to a transformation.
  """
  @moduledoc section: [:io, :errors]
  use Splode.Error, fields: [:message], class: :invalid

  @type t() :: Splode.Error.t()
end
