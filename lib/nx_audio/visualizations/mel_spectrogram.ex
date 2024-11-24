if not Code.ensure_loaded?(VegaLite) do
  defmodule NxAudio.Visualizations.MelSpectrogram do
    def plot(mel_spectrogram, opts \\ []) do
      raise "VegaLite is required to use this module. Add `{:vega_lite, \"~> 0.1\"}` to your dependencies."
    end
  end
else
  defmodule NxAudio.Visualizations.MelSpectrogram do
    @moduledoc """
    Provides a binned heatmap visualization for Nx-based MEL spectrograms.

    Each MEL spectrogram index `[t, m]` or `[c, t, m]` is treated as numeric data:
      - "time_idx" = t
      - "mel_idx" = m (representing MEL frequency bands)

    Note: This module requires the `vega_lite` package to be installed.
    Add `{:vega_lite, "~> 0.1.0"}` to your dependencies.
    """

    alias VegaLite, as: Vl

    @doc """
    Plots a **binned** MEL spectrogram heatmap. The tensor can be:
      - `[time, mel]`
      - `[channels, time, mel]`

    ## Options

      * `:title`            - Plot title (default: `"MEL Spectrogram"`)
      * `:scale`            - `:linear` (default) or `:log` for color scale
      * `:color_domain`     - `[min, max]` for the color scale (e.g. `[0, 500]`)
      * `:bin_time_maxbins` - Approx. max bins for the time dimension (default 20)
      * `:bin_mel_maxbins`  - Approx. max bins for the MEL bands dimension (default 20)
      * `:width`            - Chart width in pixels (default 800)
      * `:height`           - Chart height in pixels (default 600)

    ## Example

        mel_spectrogram_tensor =
          NxAudio.Transforms.MelSpectrogram.transform(
            audio_tensor,
            sample_rate: 16000,
            n_fft: 512,
            n_mels: 80
          )

        NxAudio.Visualizations.MelSpectrogram.plot(
          mel_spectrogram_tensor,
          title: "My MEL Spectrogram",
          color_domain: [0, 300],
          bin_time_maxbins: 50,
          bin_mel_maxbins: 40
        )
    """
    def plot(mel_spectrogram, opts \\ []) do
      title = Keyword.get(opts, :title, "MEL Spectrogram")
      scale_type = Keyword.get(opts, :scale, :linear)
      color_domain = Keyword.get(opts, :color_domain, nil)
      bin_time_maxbins = Keyword.get(opts, :bin_time_maxbins, 60)
      bin_mel_maxbins = Keyword.get(opts, :bin_mel_maxbins, 60)
      width = Keyword.get(opts, :width, 800)
      height = Keyword.get(opts, :height, 600)

      # Flatten the MEL spectrogram Nx tensor into a list of maps
      {data, has_channels} = flatten_mel_spectrogram(mel_spectrogram)

      # Base Vega-Lite spec with binning on x (time) and y (mel)
      base_spec =
        Vl.new(width: width, height: height)
        |> Vl.mark(:rect, tooltip: true)
        |> Vl.encode(:x,
          field: "time_idx",
          type: :quantitative,
          bin: [maxbins: bin_time_maxbins],
          axis: [title: "Time Index"]
        )
        |> Vl.encode(:y,
          field: "mel_idx",
          type: :quantitative,
          bin: [maxbins: bin_mel_maxbins],
          axis: [title: "MEL Band Index"]
        )
        |> Vl.encode_field(:color, "amplitude",
          type: :quantitative,
          scale: build_color_scale(scale_type, color_domain)
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

    defp build_color_scale(scale_type, color_domain) do
      scale =
        []
        |> Keyword.put(:type, color_scale_type(scale_type))
        |> Keyword.put(:zero, false)
        |> Keyword.put(:nice, false)
        # Use viridis color scheme which is better for MEL spectrograms
        |> Keyword.put(:scheme, "viridis")

      if color_domain do
        Keyword.put(scale, :domain, color_domain)
      else
        scale
      end
    end

    defp color_scale_type(:log), do: :log
    defp color_scale_type(_), do: :linear

    #
    # Flattens a 2D or 3D Nx MEL spectrogram into a list of maps:
    # 2D [time, mel] => %{"time_idx" => t, "mel_idx" => m, "amplitude" => val}
    # 3D [channels, time, mel] => %{"channel" => c, "time_idx" => t, "mel_idx" => m, "amplitude" => val}
    defp flatten_mel_spectrogram(tensor) do
      shape = Nx.shape(tensor)
      rank = Nx.rank(tensor)
      nested = Nx.to_list(tensor)

      case {rank, shape} do
        # 2D [time, mel]
        {2, {time_len, mel_len}} ->
          data =
            for t <- 0..(time_len - 1),
                m <- 0..(mel_len - 1) do
              %{
                "time_idx" => t,
                "mel_idx" => m,
                "amplitude" => nested |> Enum.at(t) |> Enum.at(m)
              }
            end

          {data, false}

        # 3D [channels, time, mel]
        {3, {channels, time_len, mel_len}} ->
          data =
            for c <- 0..(channels - 1),
                t <- 0..(time_len - 1),
                m <- 0..(mel_len - 1) do
              %{
                "channel" => c,
                "time_idx" => t,
                "mel_idx" => m,
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
                "Unexpected MEL spectrogram shape #{inspect(shape)}. " <>
                  "Expected [time, mel] or [channels, time, mel]."
      end
    end
  end
end
