if not Code.ensure_loaded?(VegaLite) do
  defmodule NxAudio.Visualizations.Spectrogram do
    def plot(spectrogram, opts \\ []) do
      raise "VegaLite is required to use this module. Add `{:vega_lite, \"~> 0.1.0\"}` to your dependencies."
    end
  end
else
  defmodule NxAudio.Visualizations.Spectrogram do
    @moduledoc """
    Provides a binned heatmap visualization for Nx-based spectrograms (no real-world conversion).

    Each spectrogram index `[t, f]` or `[c, t, f]` is treated as numeric data:
      - "time_idx" = t
      - "freq_idx" = f

    Note: This module requires the `vega_lite` package to be installed.
    Add `{:vega_lite, "~> 0.1.0"}` to your dependencies.
    """

    alias VegaLite, as: Vl

    @doc """
    Plots a **binned** spectrogram heatmap. The tensor can be:
      - `[time, freq]`
      - `[channels, time, freq]`

    ## Options

      * `:title`            - Plot title (default: `"Spectrogram"`)
      * `:scale`            - `:linear` (default) or `:log` for color scale
      * `:color_domain`     - `[min, max]` for the color scale (e.g. `[0, 500]`)
      * `:bin_time_maxbins` - Approx. max bins for the time dimension (default 20)
      * `:bin_freq_maxbins` - Approx. max bins for the frequency dimension (default 20)
      * `:width`            - Chart width in pixels (default 800)
      * `:height`           - Chart height in pixels (default 600)

    ## Example

        spectrogram_tensor =
          NxAudio.Transforms.Spectrogram.transform(
            audio_tensor,
            n_fft: 512,
            power: 2
          )

        NxAudio.Visualizations.Spectrogram.plot(
          spectrogram_tensor,
          title: "My Binned Spectrogram",
          color_domain: [0, 300],
          bin_time_maxbins: 50,
          bin_freq_maxbins: 40
        )
    """
    def plot(spectrogram, opts \\ []) do
      title = Keyword.get(opts, :title, "Spectrogram")
      scale_type = Keyword.get(opts, :scale, :linear)
      color_domain = Keyword.get(opts, :color_domain, nil)
      bin_time_maxbins = Keyword.get(opts, :bin_time_maxbins, 20)
      bin_freq_maxbins = Keyword.get(opts, :bin_freq_maxbins, 20)
      width = Keyword.get(opts, :width, 800)
      height = Keyword.get(opts, :height, 600)

      # Flatten the spectrogram Nx tensor into a list of maps
      {data, has_channels} = flatten_spectrogram(spectrogram)

      # Base Vega-Lite spec with binning on x (time) and y (freq)
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
          field: "freq_idx",
          type: :quantitative,
          bin: [maxbins: bin_freq_maxbins],
          axis: [title: "Frequency Index"]
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
        # Use magma color scheme
        |> Keyword.put(:scheme, "magma")

      if color_domain do
        Keyword.put(scale, :domain, color_domain)
      else
        scale
      end
    end

    defp color_scale_type(:log), do: :log
    defp color_scale_type(_), do: :linear

    #
    # Flattens a 2D or 3D Nx spectrogram into a list of maps:
    # 2D [time, freq] => %{"time_idx" => t, "freq_idx" => f, "amplitude" => val}
    # 3D [channels, time, freq] => %{"channel" => c, "time_idx" => t, "freq_idx" => f, "amplitude" => val}
    defp flatten_spectrogram(tensor) do
      shape = Nx.shape(tensor)
      rank = Nx.rank(tensor)
      nested = Nx.to_list(tensor)

      case {rank, shape} do
        # 2D [time, freq]
        {2, {time_len, freq_len}} ->
          data =
            for t <- 0..(time_len - 1),
                f <- 0..(freq_len - 1) do
              %{
                "time_idx" => t,
                "freq_idx" => f,
                "amplitude" => nested |> Enum.at(t) |> Enum.at(f)
              }
            end

          {data, false}

        # 3D [channels, time, freq]
        {3, {channels, time_len, freq_len}} ->
          data =
            for c <- 0..(channels - 1),
                t <- 0..(time_len - 1),
                f <- 0..(freq_len - 1) do
              %{
                "channel" => c,
                "time_idx" => t,
                "freq_idx" => f,
                "amplitude" =>
                  nested
                  |> Enum.at(c)
                  |> Enum.at(t)
                  |> Enum.at(f)
              }
            end

          {data, true}

        _ ->
          raise ArgumentError,
                "Unexpected spectrogram shape #{inspect(shape)}. " <>
                  "Expected [time, freq] or [channels, time, freq]."
      end
    end
  end
end
