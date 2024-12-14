defmodule NxAudio.Transforms.MelSpectrogramConfig do
  @moduledoc """
  Configuration options for mel spectrogram transformation.
  """
  @schema NimbleOptions.new!(
            sample_rate: [
              type: :non_neg_integer,
              default: 16_000,
              doc: "Sample rate of audio signal."
            ],
            n_fft: [
              type: :non_neg_integer,
              default: 400,
              doc: "Size of FFT, creates n_fft // 2 + 1 bins."
            ],
            win_length: [
              type: :non_neg_integer,
              doc: "Number of samples in each frame. By default its n_fft."
            ],
            hop_length: [
              type: :non_neg_integer,
              doc: """
              Number of samples between successive frames. By default its win_length/2.
              """
            ],
            f_min: [
              type: :float,
              default: 0.0,
              doc: "Minimum frequency."
            ],
            f_max: [
              type: :float,
              default: nil,
              doc: "Maximum frequency."
            ],
            pad: [
              type: :non_neg_integer,
              default: 0,
              doc: "Two sided padding of signal."
            ],
            n_mels: [
              type: :non_neg_integer,
              default: 128,
              doc: "Number of mel filterbanks."
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
            ],
            norm: [
              type: {:in, [:slaney]},
              doc: """
              If “slaney”, divide the triangular mel weights by the width of the mel band (area normalization).
              """
            ],
            mel_scale: [
              type: {:in, [:htk, :slaney]},
              default: :htk,
              doc: """
              Scale to use
              """
            ]
          )

  import Nx.Defn

  @typedoc """
  #{NimbleOptions.docs(@schema)}
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Parses and validate a keyword list into a valid mel spectrogram config
  """
  defn validate(config) do
    config
    |> keyword!(
      sample_rate: 16_000,
      n_fft: 400,
      win_length: -1,
      hop_length: -1,
      f_min: 0.0,
      f_max: -1,
      pad: 0,
      n_mels: 128,
      window_fn: &NxAudio.Commons.Windows.haan/1,
      power: 2.0,
      normalized: nil,
      wkwargs: [],
      center: true,
      pad_mode: :reflect,
      onesided: true,
      norm: nil,
      mel_scale: :htk
    )
  end
end
