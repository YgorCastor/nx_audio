defmodule NxAudio.Visualizations.Wave do
  @moduledoc """
  Provides a waveform visualization for Nx-based audio tensors.
  """
  @moduledoc section: :visualizations

  alias VegaLite, as: Vl

  @doc """
  Creates a waveform visualization from audio tensor data.

  Expects a tensor with shape [channels, samples] where:
  - channels: number of audio channels
  - samples: number of audio samples

  ## Options
    * `:width` - Width of the plot in pixels. Defaults to 800
    * `:height` - Height of the plot in pixels. Defaults to 200 
    * `:color` - Color of the waveform. Defaults to "steelblue"
    * `:background` - Background color. Defaults to "white"
    
  Returns a VegaLite specification that can be rendered.
  """
  def plot!(tensor, opts \\ []) do
    if Code.ensure_loaded?(VegaLite) do
      opts = NxAudio.Visualizations.WaveConfig.validate!(opts)

      {channels, samples} = Nx.shape(tensor)

      points =
        for c <- 0..(channels - 1),
            s <- 0..(samples - 1) do
          value = tensor[c][s] |> Nx.to_number()

          %{
            x: s,
            y: value,
            channel: "Channel #{c + 1}"
          }
        end

      Vl.new(width: opts[:width], height: opts[:height], background: opts[:background])
      |> Vl.data_from_values(points)
      |> Vl.mark(:line)
      |> Vl.encode_field(:x, "x", type: :quantitative, title: "Sample")
      |> Vl.encode_field(:y, "y", type: :quantitative, title: "Amplitude")
      |> Vl.encode_field(:color, "channel", type: :nominal)
      |> Vl.config(
        view: [stroke: nil],
        line: %{color: opts[:color]}
      )
    else
      raise "VegaLite is required to use this module. Add `{:vega_lite, \"~> 0.1\"}` to your dependencies."
    end
  end
end
