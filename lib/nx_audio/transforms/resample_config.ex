defmodule NxAudio.Transforms.ResampleConfig do
  @moduledoc """
  Configuration options for audio resampling transformation.
  """
  @moduledoc section: :transforms

  @schema NimbleOptions.new!(
            orig_freq: [
              type: :non_neg_integer,
              default: 16_000,
              doc: "Original sampling frequency of the audio."
            ],
            new_freq: [
              type: :non_neg_integer,
              default: 16_000,
              doc: "Target sampling frequency for resampling."
            ],
            resampling_method: [
              type: {:in, [:sinc_interp_hann, :sinc_interp_kaiser]},
              default: :sinc_interp_hann,
              doc: "Method used for resampling the audio signal."
            ],
            lowpass_filter_width: [
              type: :non_neg_integer,
              default: 6,
              doc: "Width of the lowpass filter used in resampling."
            ],
            rolloff: [
              type: :float,
              default: 0.99,
              doc: "Roll-off frequency of the filter as a fraction of the Nyquist frequency."
            ],
            beta: [
              type: {:or, [:float, nil]},
              default: 12.0,
              doc: "Kaiser window beta parameter. Only used when window type is kaiser."
            ]
          )

  @typedoc """
  #{NimbleOptions.docs(@schema)}
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Parses and validates a keyword list into a valid resample config
  """
  def validate!(config) do
    config
    |> NimbleOptions.validate!(@schema)
  end
end
