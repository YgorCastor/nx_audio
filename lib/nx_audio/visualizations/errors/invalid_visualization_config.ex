defmodule NxAudio.Visualizations.Errors.InvalidVisualizationConfig do
  @moduledoc """
  Error when a invalid configuration is provided to a visualization.
  """
  @moduledoc section: [:visualizations]
  use Splode.Error, fields: [:message], class: :invalid

  @type t() :: Splode.Error.t()
end
