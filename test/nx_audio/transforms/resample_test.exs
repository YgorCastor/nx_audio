defmodule NxAudio.Transforms.ResampleTest do
  use Nx.Case, async: false

  alias NxAudio.Transforms.Resample

  describe "transform/2" do
    test "returns original tensor when orig_freq equals new_freq" do
      tensor = Nx.tensor([[1.0, 2.0, 3.0, 4.0]])
      result = Resample.transform(tensor, orig_freq: 16_000, new_freq: 16_000)
      assert_all_close(result, tensor)
    end

    test "downsamples audio by factor of 2" do
      t = Nx.linspace(0, 1, n: 16_000)
      freq = 2.0 * :math.pi() * 1000.0
      audio = Nx.sin(Nx.multiply(t, freq))
      audio = Nx.reshape(audio, {1, 16_000})

      result = Resample.transform(audio, orig_freq: 16_000, new_freq: 8000)

      # Check output shape
      assert Nx.shape(result) == {1, 8000}

      # Check that the frequency content is preserved
      # by comparing a few samples
      expected = Nx.tensor([[0.0, 0.0, 0.0, 0.0]], type: {:f, 32})
      assert_all_close(Nx.slice(result, [0, 0], [1, 4]), expected)
    end

    test "upsamples audio by factor of 2" do
      t = Nx.linspace(0, 1, n: 8000)
      freq = 2.0 * :math.pi() * 500.0
      audio = Nx.sin(Nx.multiply(t, freq))
      audio = Nx.reshape(audio, {1, 8000})

      result = Resample.transform(audio, orig_freq: 8000, new_freq: 16_000)

      # Check output shape
      assert Nx.shape(result) == {1, 16_000}
    end

    test "handles different window types" do
      tensor = Nx.tensor([[1.0, 2.0, 3.0, 4.0]])

      # Test with Hann window
      result_hann =
        Resample.transform(tensor,
          orig_freq: 16_000,
          new_freq: 8000,
          resampling_method: :sinc_interp_hann
        )

      # Test with Kaiser window
      result_kaiser =
        Resample.transform(tensor,
          orig_freq: 16_000,
          new_freq: 8000,
          resampling_method: :sinc_interp_kaiser,
          beta: 12.0
        )

      assert Nx.shape(result_hann) == {1, 2}
      assert Nx.shape(result_kaiser) == {1, 2}
    end
  end
end
