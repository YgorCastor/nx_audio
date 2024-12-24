defmodule NxAudio.Visualizations.SpectrogramConfig do
  @moduledoc """
  Defines the configuration schema for the Spectrogram visualization.
  """
  @moduledoc section: :visualizations

  @schema NimbleOptions.new!(
            title: [
              type: :string,
              default: "Spectrogram",
              doc: "Title of the plot."
            ],
            scale_type: [
              type: {:in, [:linear, :log]},
              default: :linear,
              doc: "Scale for the color encoding."
            ],
            color_domain: [
              type: :any,
              doc: "`[min, max]` for the color scale (e.g. `[0, 500]`)"
            ],
            color_scheme: [
              type: {:in, [:viridis, :inferno, :plasma, :magma, :cividis]},
              default: :viridis,
              doc: "Color scheme for the plot."
            ],
            bin_maxbins: [
              type: :non_neg_integer,
              default: 60,
              doc: "Approx. max bins for the time and frequency dimensions."
            ],
            x_axis_label: [
              type: :string,
              default: "Time Index",
              doc: "Label for the x-axis."
            ],
            y_axis_label: [
              type: :string,
              default: "Frequency Index",
              doc: "Label for the y-axis."
            ],
            width: [
              type: :non_neg_integer,
              default: 800,
              doc: "Chart width in pixels."
            ],
            height: [
              type: :non_neg_integer,
              default: 600,
              doc: "Chart height in pixels."
            ]
          )

  alias NxAudio.Visualizations.Errors

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Validates the given configuration options and returns the parsed configuration.
  """
  @spec validate!(backend_options :: Keyword.t()) :: t()
  def validate!(config) do
    case NimbleOptions.validate(config, @schema) do
      {:ok, parsed_config} ->
        parsed_config

      {:error, error} ->
        raise Errors.InvalidVisualizationConfig.exception(message: error.message)
    end
  end
end
