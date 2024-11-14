defmodule NxAudio.Transforms.MelSpectrogram do
  @moduledoc """
  Implements Mel-scaled spectrograms - a perceptually-motivated time-frequency representation of audio.

  The mel spectrogram applies mel filterbanks to a regular spectrogram, mapping linear frequency bins to the mel scale that better approximates human auditory perception.

  ## Mel Scale

  The mel scale relates perceived frequency to actual frequency in Hz. Two main formulas are supported:

  HTK (default):
  $$ m = 2595 \log_{10}(1 + \frac{f}{700}) $$

  Slaney:
  $$ m = \begin{cases} 
  f/f_{min} \cdot m_{min} & f < f_{min} \\
  m_{min} + \log(f/f_{min})/\text{step} & f \geq f_{min}
  \end{cases} $$

  where $f_{min}=1000$, $m_{min}=25$, $\text{step}=\log(6.4)/27$

  ## Filterbank Construction

  Mel filterbanks are triangular overlapping windows spaced uniformly on the mel scale:

  1. Convert frequencies to mel scale
  2. Create `n_mels + 2` points evenly spaced in mel scale
  3. Convert back to Hz to get filterbank center frequencies
  4. Create triangular filters:

  $$ H_m(k) = \begin{cases}
  0 & k < f(m-1) \\
  \frac{k - f(m-1)}{f(m) - f(m-1)} & f(m-1) \leq k < f(m) \\
  \frac{f(m+1) - k}{f(m+1) - f(m)} & f(m) \leq k < f(m+1) \\
  0 & k \geq f(m+1)
  \end{cases} $$

  where $f(m)$ is the frequency of filterbank $m$.

  ## Applications

  Mel spectrograms are widely used in:
  - Speech recognition
  - Music information retrieval  
  - Audio classification
  - Sound event detection
  - Speaker identification

  By mapping frequencies to a perceptual scale and reducing dimensionality, mel spectrograms provide an efficient and meaningful audio representation.
  """

  import Nx.Defn
  import NxAudio.Transforms.MelSpectrogramConfig

  alias NxAudio.Transforms.Spectrogram

  @doc """
  Computes the mel-scaled spectrogram of an audio signal.

  Args:
    audio_tensor: Input audio tensor of shape [samples] or [channels, samples]
    config: MelSpectrogram configuration options `NxAudio.Transforms.MelSpectrogramConfig`

  Returns:
    If input is [samples]: Returns tensor of shape [time, n_mels]
    If input is [channels, samples]: Returns tensor of shape [channels, time, n_mels]
  """
  defn transform(audio_tensor, opts \\ []) do
    opts = validate(opts)

    # First compute regular spectrogram
    spectrogram_opts = to_spectrogram_config(opts)
    spec = Spectrogram.transform(audio_tensor, spectrogram_opts)

    # Create mel filterbank matrix
    mel_basis = create_mel_filterbank(opts)

    # Apply mel filterbank
    apply_filterbank(spec, mel_basis)
  end

  defnp to_spectrogram_config(mel_opts) do
    [
      n_fft: mel_opts[:n_fft],
      win_length: mel_opts[:win_length],
      hop_length: mel_opts[:hop_length],
      pad: mel_opts[:pad],
      window_fn: mel_opts[:window_fn],
      power: mel_opts[:power],
      normalized: mel_opts[:normalized],
      wkwargs: mel_opts[:wkwargs],
      center: mel_opts[:center],
      pad_mode: mel_opts[:pad_mode],
      onesided: mel_opts[:onesided]
    ]
  end

  defnp create_mel_filterbank(opts) do
    sr = opts[:sample_rate]
    n_fft = opts[:n_fft]
    n_mels = opts[:n_mels]
    f_min = opts[:f_min]
    f_max = if opts[:f_max] != -1, do: opts[:f_max], else: sr / 2

    # Get frequencies for FFT bins
    fft_freqs = Nx.linspace(0, sr / 2, n: div(n_fft, 2) + 1)

    # Convert Hz to mel scale
    mel_min = hz_to_mel(f_min, opts)
    mel_max = hz_to_mel(f_max, opts)
    mel_points = Nx.linspace(mel_min, mel_max, n: n_mels + 2)

    # Convert back to Hz
    bin_freqs = mel_to_hz(mel_points, opts)

    # Create filterbank matrix
    fb = create_triangular_filters(fft_freqs, bin_freqs)

    case opts[:norm] do
      :slaney -> normalize_filterbank(fb)
      _ -> fb
    end
  end

  @min_log_hz 1000.0
  @min_log_mel @min_log_hz / 40.0
  @mel_step Nx.log(6.4) / 27.0
  @htk_mul 1127.0
  @frequency_ref 700.0

  defnp hz_to_mel(freq, opts) do
    case opts[:mel_scale] do
      :htk ->
        @htk_mul * Nx.log(1.0 + freq / @frequency_ref)

      _ ->
        freq =
          Nx.select(
            freq > @min_log_hz,
            @min_log_mel + Nx.log(freq / @min_log_hz) / @mel_step,
            freq / @min_log_hz * @min_log_mel
          )

        @min_log_mel + Nx.log(1 + freq / @frequency_ref) * @htk_mul
    end
  end

  defnp mel_to_hz(mel, opts) do
    case opts[:mel_scale] do
      :htk ->
        @frequency_ref * (Nx.exp(mel / @htk_mul) - 1.0)

      _ ->
        Nx.select(
          mel > @min_log_mel,
          @min_log_hz * Nx.exp(@mel_step * (mel - @min_log_mel)),
          @min_log_hz * mel / @min_log_mel
        )
    end
  end

  defnp create_triangular_filters(fft_freqs, mel_freqs) do
    n_freqs = Nx.size(fft_freqs)
    n_mels = Nx.size(mel_freqs) - 2

    indices = Nx.iota({n_mels})
    f_left = Nx.reshape(Nx.take(mel_freqs, indices), {n_mels, 1})
    f_center = Nx.reshape(Nx.take(mel_freqs, indices + 1), {n_mels, 1})
    f_right = Nx.reshape(Nx.take(mel_freqs, indices + 2), {n_mels, 1})

    fft_expanded = Nx.reshape(fft_freqs, {1, n_freqs})

    left_slope = (fft_expanded - f_left) / (f_center - f_left)
    right_slope = (f_right - fft_expanded) / (f_right - f_center)

    Nx.select(
      left_slope > 0 and right_slope > 0,
      Nx.min(left_slope, right_slope),
      0.0
    )
  end

  defnp normalize_filterbank(filterbank) do
    enorm = 2.0 / (mel_to_hz(2, mel_scale: :slaney) - mel_to_hz(0, mel_scale: :slaney))
    filterbank * enorm
  end

  defnp apply_filterbank(spec, mel_basis) do
    case Nx.rank(spec) do
      2 ->
        Nx.dot(spec, Nx.transpose(mel_basis))

      3 ->
        {n_channels, n_frames, n_freqs} = Nx.shape(spec)
        # Reshape to 2D for dot product
        spec = Nx.reshape(spec, {n_frames, n_freqs})
        result = Nx.dot(spec, Nx.transpose(mel_basis))
        # Reshape back to 3D
        Nx.reshape(result, {n_channels, n_frames, :auto})
    end
  end
end
