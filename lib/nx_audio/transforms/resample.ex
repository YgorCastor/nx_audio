defmodule NxAudio.Transforms.Resample do
  @moduledoc """
  Provides high-quality audio resampling using sinc interpolation.

  This module implements a polyphase resampling algorithm that changes the sampling rate
  of an audio signal while maintaining high fidelity. The process involves three main steps:

  1. Upsampling by factor L (insertion of L-1 zeros between samples)
  2. Lowpass filtering with a windowed-sinc kernel
  3. Downsampling by factor M (keeping every Mth sample)

  The mathematical foundation is based on the following equations:

  ## Sinc Filter
  The ideal lowpass filter kernel is the sinc function:

  $h[n] = \\text{sinc}(n) = \\frac{\\sin(\\pi n)}{\\pi n}$

  ## Window Functions
  The infinite sinc is truncated using either, hann or kaiser window functions

  ## Resampling Process
  The complete resampling operation can be expressed as:

  $y[n] = \\sum_{k} x[k] h[nM/L - k]$

  where:
  * x[n] is the input signal
  * y[n] is the resampled output
  * L is the upsampling factor
  * M is the downsampling factor
  * h[n] is the windowed-sinc filter

  The implementation uses efficient polyphase decomposition and the GCD of the
  target and source sampling rates to minimize computational complexity.
  """
  @moduledoc section: :transforms
  import Nx.Defn

  alias NxAudio.Commons.Windows
  alias NxAudio.Transforms.ResampleConfig

  @behaviour NxAudio.Transforms

  @pi :math.pi()

  @doc """
  Receives an audio tensor in the format {channels, samples} and resamples it to a new frequency.  

  For options, check `NxAudio.Transforms.ResampleConfig`.
  """
  @impl true
  @spec transform(NxAudio.IO.audio_tensor(), ResampleConfig.t()) ::
          NxAudio.IO.audio_tensor()
  def transform(audio_tensor, opts \\ []) do
    opts = ResampleConfig.validate!(opts)
    orig_freq = opts[:orig_freq]
    new_freq = opts[:new_freq]

    if orig_freq == new_freq do
      audio_tensor
    else
      gcd = Integer.gcd(orig_freq, new_freq)
      up_factor = div(new_freq, gcd)
      down_factor = div(orig_freq, gcd)

      do_transform(audio_tensor,
        up_factor: up_factor,
        down_factor: down_factor,
        lowpass_filter_width: opts[:lowpass_filter_width],
        rolloff: opts[:rolloff],
        resampling_method: opts[:resampling_method],
        beta: opts[:beta]
      )
    end
  end

  defn do_transform(audio_tensor, opts \\ []) do
    up_factor = opts[:up_factor]
    down_factor = opts[:down_factor]
    filter_width = opts[:lowpass_filter_width]

    half_width = div(filter_width * up_factor, 2)
    kernel_size = 2 * half_width + 1
    cutoff = opts[:rolloff] * min(1.0, up_factor / down_factor)

    # Generate sinc filter
    n = Nx.iota({kernel_size}, type: {:f, 32})
    n = n - half_width

    # Create base sinc filter
    sinc = sinc(n * cutoff / up_factor)

    window =
      case opts[:resampling_method] do
        :sinc_interp_hann ->
          Windows.haan(window_length: kernel_size, periodic: false)

        :sinc_interp_kaiser ->
          Windows.kaiser(kernel_size, beta: opts[:beta], is_periodic: false)
      end

    kernel = sinc * window * cutoff

    # Normalize kernel considering upsampling factor
    kernel = kernel / (Nx.sum(kernel) * up_factor)

    # Perform resampling
    resample_with_kernel(audio_tensor, kernel, up_factor, down_factor)
  end

  defnp sinc(x) do
    # Handle x = 0 case
    zeros = Nx.equal(x, 0)
    x = Nx.select(zeros, 1.0e-20, x)

    sin = Nx.sin(@pi * x)
    result = sin / (@pi * x)

    # Replace 0/0 with 1
    Nx.select(zeros, 1.0, result)
  end

  defnp resample_with_kernel(audio, kernel, up_factor, down_factor) do
    # Upsample by inserting zeros
    upsampled = upsample(audio, up_factor)

    # Reshape inputs to add channel dimension for convolution
    kernel_3d = Nx.reshape(kernel, {1, 1, Nx.size(kernel)})
    upsampled_3d = Nx.reshape(upsampled, {1, 1, elem(Nx.shape(upsampled), 1)})

    filtered =
      Nx.conv(upsampled_3d, kernel_3d,
        strides: down_factor,
        padding: :same
      )
      |> Nx.reshape({1, :auto})

    # Scale the output
    filtered * up_factor
  end

  defnp upsample(x, factor) do
    {channels, length} = Nx.shape(x)
    new_length = length * factor

    zeros = Nx.broadcast(0.0, {channels, new_length})

    # Create indices for both dimensions
    channel_indices = Nx.reshape(Nx.iota({channels}), {channels, 1})
    channel_indices = Nx.broadcast(channel_indices, {channels, length})

    sample_indices = Nx.reshape(Nx.iota({length}) * factor, {1, length})
    sample_indices = Nx.broadcast(sample_indices, {channels, length})

    # Reshape indices and values for indexed_put
    indices =
      Nx.stack(
        [
          Nx.reshape(channel_indices, {:auto}),
          Nx.reshape(sample_indices, {:auto})
        ],
        axis: 1
      )

    x_flat = Nx.reshape(x, {:auto})

    Nx.indexed_put(zeros, indices, x_flat)
  end
end
