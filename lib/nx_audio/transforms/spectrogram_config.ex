defmodule NxAudio.Transforms.SpectrogramConfig do
  @moduledoc """
  Configuration options for spectrogram transformation.
  """
  @moduledoc section: :transforms

  @schema NimbleOptions.new!(
            n_fft: [
              type: :non_neg_integer,
              default: 400,
              doc: "Size of FFT, creates n_fft // 2 + 1 bins."
            ],
            win_length: [
              type: :non_neg_integer,
              doc: "Number of samples in each frame. By default its half of the n_fft"
            ],
            hop_length: [
              type: :non_neg_integer,
              doc: """
              Number of samples between successive frames., By default its half of the n_fft
              """
            ],
            pad: [
              type: :non_neg_integer,
              default: 0,
              doc: "Two sided padding of signal."
            ],
            window_fn: [
              default: &NxAudio.Commons.Windows.haan/1,
              doc: "Window function to apply to each frame."
            ],
            power: [
              type: :float,
              default: 2,
              doc: """
              Exponent for the magnitude spectrogram, (must be > 0) e.g., 1 for magnitude, 2 for power, etc. If None, then the complex spectrum is returned instead. 
              """
            ],
            normalized: [
              type: {:in, [:window, :frame_length]},
              doc: """
              Whether to normalize by magnitude after stft. choices are "window" and "frame_length", if specific normalization type is desirable.
              """
            ],
            wkwargs: [
              type: :keyword_list,
              default: [],
              doc: "Arguments for window function."
            ],
            center: [
              type: :boolean,
              default: true,
              doc: """
              Whether to pad waveform on both sides so that the t-th frame is centered at time t * hop_length.
              """
            ],
            pad_mode: [
              type: :atom,
              default: :reflect,
              doc: """
              Controls the padding method used when center is true.
              """
            ],
            onesided: [
              type: :boolean,
              default: true,
              doc: """
              Controls whether to return half of results to avoid redundancy.
              """
            ]
          )

  import Nx.Defn

  @typedoc """
  #{NimbleOptions.docs(@schema)}
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Parses and validate a keyword list into a valid spectrogram config
  """
  defn validate(config) do
    config
    |> keyword!(
      n_fft: 400,
      win_length: -1,
      hop_length: -1,
      pad: 0,
      window_fn: &NxAudio.Commons.Windows.haan/1,
      power: 2.0,
      normalized: nil,
      wkwargs: [],
      center: true,
      pad_mode: :reflect,
      onesided: true
    )
  end

  defn maybe_calculate_win_length(win_length, n_fft) do
    if win_length != -1 do
      win_length
    else
      n_fft
    end
  end

  defn maybe_calculate_hop_length(hop_length, win_length) do
    if hop_length != -1 do
      hop_length
    else
      div(win_length, 2)
    end
  end
end
