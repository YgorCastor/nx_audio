defmodule NxAudio.Transforms.MelSpectrogramTest do
  use Nx.Case, async: true

  import NxAudio.Fixtures.AudioTensors

  alias NxAudio.Transforms.MelSpectrogram

  test "should compute mel spectrogram correctly" do
    audio_tensor = new_pcm_with_sr(22_050)
    mel_spec = MelSpectrogram.transform(audio_tensor, sample_rate: 22_050, n_mels: 128)

    {channels, n_frames, n_mels} = Nx.shape(mel_spec)

    # Test shape
    assert n_mels == 128
    assert n_frames > 0
    assert channels == 1

    # Test mel scaling - 440Hz tone should activate specific mel bins
    # Convert 440Hz to mel scale (HTK)
    mel_440 = 2595 * :math.log10(1 + 440 / 700)
    # Find corresponding mel bin
    mel_step = 2595 * :math.log10(1 + 22050 / 2 / 700) / 128
    expected_bin = floor(mel_440 / mel_step)

    mean_mel_spectrum =
      mel_spec
      |> Nx.mean(axes: [0])
      |> Nx.to_flat_list()

    {_max_val, max_idx} =
      Enum.with_index(mean_mel_spectrum)
      |> Enum.max_by(fn {val, _idx} -> val end)

    # Allow 2 bin tolerance due to mel filterbank overlap
    assert abs(max_idx - expected_bin) <= 2

    # Test energy distribution
    peak_region = Enum.slice(mean_mel_spectrum, (max_idx - 3)..(max_idx + 3))

    non_peak_region =
      mean_mel_spectrum
      |> Enum.with_index()
      |> Enum.reject(fn {_, i} -> abs(i - max_idx) <= 3 end)
      |> Enum.map(fn {v, _} -> v end)

    avg_peak = Enum.sum(peak_region) / length(peak_region)
    avg_non_peak = Enum.sum(non_peak_region) / length(non_peak_region)

    # Peak should be significantly higher
    assert avg_peak > avg_non_peak * 8
  end
end
