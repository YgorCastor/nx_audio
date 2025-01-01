defmodule NxAudio.Visualizations.WaveConfig do
  @moduledoc """
  Defines the configuration schema for the Waveform visualization.
  """
  @moduledoc section: :visualizations

  @schema NimbleOptions.new!(
            width: [
              type: :non_neg_integer,
              default: 800,
              doc: "Chart width in pixels."
            ],
            height: [
              type: :non_neg_integer,
              default: 600,
              doc: "Chart height in pixels."
            ],
            color: [
              type: {:in, [:steelblue, :red, :green, :blue, :orange, :purple, :black, :white]},
              default: :steelblue,
              doc: "Color of the waveform."
            ],
            background: [
              type: {:in, [:white, :black, :red, :green, :blue, :orange, :purple]},
              default: :white,
              doc: "Background color."
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
