defmodule NxAudio.Transforms.MuLawEncoding do
  @moduledoc """
  Implementation of μ-law encoding, a form of audio signal compression.

  μ-law encoding is a signal compression technique that effectively reduces the dynamic
  range of audio signals while preserving more detail in the quieter sections. It is
  commonly used in telecommunications and digital audio systems, particularly in North
  America and Japan.

  ## Mathematical Formula

  The μ-law encoding formula is:

  $F(x) = sign(x) \\frac{ln(1 + μ|x|)}{ln(1 + μ)}$

  where:
  * $x$ is the input signal (normalized between -1 and 1)
  * $μ$ (mu) is the compression parameter (typically 255 for 8-bit encoding)
  * $sign(x)$ is the sign function

  ## How it Works

  1. The input signal is normalized to the range [-1, 1]
  2. The signal is compressed using a logarithmic function
  3. The compression is stronger for small input values and weaker for large ones
  4. This results in:
     * Better resolution for small amplitude signals
     * Reduced dynamic range for the entire signal
     * Approximately 14-bit dynamic range compressed into 8 bits

  ## Advantages

  * Reduces storage requirements while maintaining signal quality
  * Preserves more detail in quiet sounds
  * Reduces the effects of quantization noise in small signals
  * Widely used in telephony systems (8-bit PCM)

  ## References

  * ITU-T Recommendation G.711
  * Digital Signal Processing principles and implementations
  """
  @moduledoc section: :transforms

  import Nx.Defn

  @doc """
  Encodes an audio signal using mu-law encoding.

  ## Options
    * `:quantization_channels` - Number of quantization channels. Defaults to 256.

  ## Examples

      iex> tensor = Nx.tensor([0.5, -0.2, 0.1])
      iex> NxAudio.Transforms.MuLawEncoding.transform(tensor)
  """
  defn transform(audio_tensor, opts \\ []) do
    opts = keyword!(opts, quantization_channels: 256)
    mu = opts[:quantization_channels] - 1

    # Clip the signal to [-1, 1]
    x = Nx.clip(audio_tensor, -1.0, 1.0)

    # Perform mu-law encoding
    sign = Nx.sign(x)
    abs_x = Nx.abs(x)

    sign * Nx.log(1 + mu * abs_x) / Nx.log(1 + mu)
  end
end
