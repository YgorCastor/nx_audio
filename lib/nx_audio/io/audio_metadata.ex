defmodule NxAudio.IO.AudioMetadata do
  @moduledoc """
  Represents the metadata of an audio file
  """
  @moduledoc section: :io

  @enforce_keys [:sample_rate, :num_frames, :num_channels, :bits_per_sample, :encoding]
  defstruct [
    :sample_rate,
    :num_frames,
    :num_channels,
    :bits_per_sample,
    :encoding
  ]

  @typedoc """
  sample_rate: The sample rate of the audio file in Hz e.g. 44100
  num_frames: The number of frames in the audio file e.g. 1000
  num_channels: The number of channels in the audio file e.g. 2
  bits_per_sample: The number of bits per sample in the audio file e.g. 16
  encoding: The encoding of the audio file e.g. NxAudio.IO.Encoding.Type.PCM_S
  """
  @type t() :: %__MODULE__{
          sample_rate: non_neg_integer(),
          num_frames: non_neg_integer(),
          num_channels: non_neg_integer(),
          bits_per_sample: non_neg_integer(),
          encoding: NxAudio.IO.Encoding.Type.t()
        }
end
