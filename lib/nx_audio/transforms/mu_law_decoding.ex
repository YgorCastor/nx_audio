defmodule NxAudio.Transforms.MuLawDecoding do
  @moduledoc """
  Implementation of μ-law decoding, which reverses μ-law encoding compression.

  μ-law decoding takes a compressed signal (typically in the range [-1, 1]) and
  expands it back to its original form. This is the inverse operation of μ-law encoding.

  ## Mathematical Formula

  The μ-law decoding formula is:

  $F^{-1}(y) = sign(y) \\frac{(1 + μ)^{|y|} - 1}{μ}$

  where:
  * $y$ is the encoded signal (normalized between -1 and 1)
  * $μ$ (mu) is the compression parameter (typically 255 for 8-bit encoding)
  * $sign(y)$ is the sign function

  ## How it Works

  1. Takes the compressed signal (normalized between -1 and 1)
  2. Applies the inverse logarithmic function
  3. Restores the original signal's dynamic range
  4. Preserves the sign of the original signal

  ## References

  * ITU-T Recommendation G.711
  * Digital Signal Processing principles and implementations
  """
  @moduledoc section: :transforms

  import Nx.Defn

  @behaviour NxAudio.Transforms

  @doc """
  Decodes a μ-law encoded audio signal back to its original form.

  ## Options
    * `:quantization_channels` - Number of quantization channels. Defaults to 256.

  ## Examples

      iex> encoded = Nx.tensor([0.8, -0.5, 0.3])
      iex> NxAudio.Transforms.MuLawDecoding.transform(encoded)
  """
  @impl true
  @spec transform(NxAudio.IO.audio_tensor(), keyword()) ::
          NxAudio.IO.audio_tensor()
  defn transform(audio_tensor, opts \\ []) do
    opts = keyword!(opts, quantization_channels: 256)
    mu = opts[:quantization_channels] - 1

    y = Nx.clip(audio_tensor, -1.0, 1.0)

    sign = Nx.sign(y)
    abs_y = Nx.abs(y)

    sign * ((1 + mu) ** abs_y - 1) / mu
  end
end
