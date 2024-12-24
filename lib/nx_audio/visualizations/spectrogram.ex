if Code.ensure_loaded?(VegaLite) do
  defmodule NxAudio.Visualizations.Spectrogram do
    @moduledoc """
    Provides a binned heatmap visualization for Nx-based Spectrograms.

    Each Spectrogram index `[t, m or f]` or `[c, t, m or f]` is treated as numeric data:
      - "x_idx" = t
      - "y_idx" = m (representing MEL frequency bands) or f (representing linear frequency bands)

    Note: This module requires the `vega_lite` package to be installed.
    Add `{:vega_lite, "~> 0.1"}` to your dependencies.
    """
    @moduledoc section: :visualizations

    alias VegaLite, as: Vl

    @doc """
    Plots a **binned** Spectrogram heatmap. The tensor can be:
      - `[time, mel/frequency]`
      - `[channels, time, mel/frequency]`

    ## Example

        spectrogram_tensor =
          NxAudio.Transforms.MelSpectrogram.transform(
            audio_tensor,
            sample_rate: 16000,
            n_fft: 512,
            n_mels: 80
          )

        NxAudio.Visualizations.Spectrogram.plot!(
          spectrogram_tensor,
          title: "My MEL Spectrogram",
          color_domain: [0, 300],
          bin_maxbins: 50,
          bin_maxbins: 40
        )
    """
    @spec plot!(Nx.Type.t(), NxAudio.Visualizations.SpectrogramConfig.t()) :: Vl.spec()
    def plot!(mel_spectrogram, opts \\ []) do
      opts = NxAudio.Visualizations.SpectrogramConfig.validate!(opts)

      title = Keyword.get(opts, :title)
      scale_type = Keyword.get(opts, :scale_type)
      color_domain = Keyword.get(opts, :color_domain)
      color_scheme = Keyword.get(opts, :color_scheme)
      bin_maxbins = Keyword.get(opts, :bin_maxbins)
      width = Keyword.get(opts, :width)
      height = Keyword.get(opts, :height)
      x_axis_label = Keyword.get(opts, :x_axis_label)
      y_axis_label = Keyword.get(opts, :y_axis_label)

      # Flatten the Spectrogram Nx tensor into a list of maps
      {data, has_channels} = flatten_mel_spectrogram(mel_spectrogram)

      # Base Vega-Lite spec with binning on x (time) and y (frequency/mel)
      base_spec =
        Vl.new(width: width, height: height)
        |> Vl.mark(:rect, tooltip: true)
        |> Vl.encode(:x,
          field: "x_idx",
          type: :quantitative,
          bin: [maxbins: bin_maxbins],
          axis: [title: x_axis_label]
        )
        |> Vl.encode(:y,
          field: "y_idx",
          type: :quantitative,
          bin: [maxbins: bin_maxbins],
          axis: [title: y_axis_label]
        )
        |> Vl.encode_field(:color, "amplitude",
          type: :quantitative,
          scale: build_color_scale(scale_type, color_domain, color_scheme)
        )

      if has_channels do
        # If multiple channels, facet by "channel"
        Vl.new(title: title)
        |> Vl.data_from_values(data)
        |> Vl.facet([field: "channel", type: :nominal, header: [title: "Channels"]], base_spec)
      else
        # Single channel
        Vl.new(title: title)
        |> Vl.data_from_values(data)
        |> Vl.layers([base_spec])
      end
    end

    defp build_color_scale(scale_type, color_domain, color_scheme) do
      scale =
        []
        |> Keyword.put(:type, color_scale_type(scale_type))
        |> Keyword.put(:zero, false)
        |> Keyword.put(:nice, false)
        |> Keyword.put(:scheme, Atom.to_string(color_scheme))

      if color_domain do
        Keyword.put(scale, :domain, color_domain)
      else
        scale
      end
    end

    defp color_scale_type(:log), do: :log
    defp color_scale_type(_), do: :linear

    #
    # Flattens a 2D or 3D Nx Spectrogram into a list of maps:
    # 2D [time, mel] => %{"x_idx" => t, "y_idx" => m, "amplitude" => val}
    # 3D [channels, time, mel] => %{"channel" => c, "x_idx" => t, "y_idx" => m, "amplitude" => val}
    defp flatten_mel_spectrogram(tensor) do
      shape = Nx.shape(tensor)
      rank = Nx.rank(tensor)
      nested = Nx.to_list(tensor)

      case {rank, shape} do
        {2, {x_len, y_len}} ->
          data =
            for t <- 0..(x_len - 1),
                m <- 0..(y_len - 1) do
              %{
                "x_idx" => t,
                "y_idx" => m,
                "amplitude" => nested |> Enum.at(t) |> Enum.at(m)
              }
            end

          {data, false}

        # 3D [channels, time, mel]
        {3, {channels, x_len, y_len}} ->
          data =
            for c <- 0..(channels - 1),
                t <- 0..(x_len - 1),
                m <- 0..(y_len - 1) do
              %{
                "channel" => c,
                "x_idx" => t,
                "y_idx" => m,
                "amplitude" =>
                  nested
                  |> Enum.at(c)
                  |> Enum.at(t)
                  |> Enum.at(m)
              }
            end

          {data, true}

        _ ->
          raise ArgumentError,
                "Unexpected Spectrogram shape #{inspect(shape)}. " <>
                  "Expected [time, x] or [channels, time, x]."
      end
    end
  end
else
  defmodule NxAudio.Visualizations.Spectrogram do
    @moduledoc false

    def plot(_spectrogram, _opts \\ []) do
      raise "VegaLite is required to use this module. Add `{:vega_lite, \"~> 0.1\"}` to your dependencies."
    end
  end
end
