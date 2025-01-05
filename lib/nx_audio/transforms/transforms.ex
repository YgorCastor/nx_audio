defmodule NxAudio.Transforms do
  @moduledoc """
  Defines a behaviour for audio transformations
  """

  @doc """
  Represents the transformation of an audio tensor
  """
  @callback transform(NxAudio.IO.audio_tensor(), keyword()) :: NxAudio.IO.audio_tensor()
end
