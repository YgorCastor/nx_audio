defmodule NxAudio.Visualizations.Errors.InvalidVisualizationConfig do
  @moduledoc section: [:visualizations]
  use Splode.Error, fields: [:message], class: :invalid

  @type t() :: Splode.Error.t()
end
