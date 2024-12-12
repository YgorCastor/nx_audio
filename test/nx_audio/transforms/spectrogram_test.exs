defmodule NxAudio.Transforms.SpectrogramTest do
  use Nx.Case, async: true

  import NxAudio.Fixtures.AudioTensors

  alias NxAudio.Transforms.Spectrogram

  @tag timeout: 600_000
  test "should be able to compute a spectrogram correctly" do
    audio_tensor = new_pcm_with_sr(22_050)

    spec = Spectrogram.transform(audio_tensor)

    {channels, n_frames, n_freqs} = Nx.shape(spec)

    # Test 1: Verify output shape
    assert n_freqs == div(400, 2) + 1
    assert n_frames > 0
    assert channels == 2

    # Test 2: Find peak frequency bin

    # For 440Hz at 22050Hz sample rate with 400-point FFT:
    # bin_freq = sample_rate * bin_index / n_fft
    # expected_bin ≈ 440 * 400 / 22050 ≈ 8
    expected_bin = floor(440 * 400 / 22_050)

    # Get the average magnitude across all frames
    mean_spectrum =
      spec
      |> Nx.mean(axes: [0])
      |> Nx.to_flat_list()

    # Find the bin with maximum energy
    {_max_val, max_idx} =
      Enum.with_index(mean_spectrum)
      |> Enum.max_by(fn {val, _idx} -> val end)

    # Check if peak is near expected frequency
    # Allow 1 bin tolerance
    assert abs(max_idx - expected_bin) <= 1

    # Test 3: Check if other frequencies have significantly less energy
    peak_region = Enum.slice(mean_spectrum, (max_idx - 2)..(max_idx + 2))

    non_peak_region =
      mean_spectrum
      |> Enum.with_index()
      |> Enum.reject(fn {_, i} -> abs(i - max_idx) <= 2 end)
      |> Enum.map(fn {v, _} -> v end)

    avg_peak = Enum.sum(peak_region) / length(peak_region)
    avg_non_peak = Enum.sum(non_peak_region) / length(non_peak_region)

    # Peak should be significantly higher than background
    assert avg_peak > avg_non_peak * 10
  end
end
