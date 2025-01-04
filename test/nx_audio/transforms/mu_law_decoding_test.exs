defmodule NxAudio.Transforms.MuLawDecodingTest do
  use Nx.Case, async: true

  alias NxAudio.Transforms.MuLawEncoding
  alias NxAudio.Transforms.MuLawDecoding

  describe "transform/2" do
    test "decodes signal with default quantization channels" do
      input = Nx.tensor([-1.0, -0.5, 0.0, 0.5, 1.0])
      result = MuLawDecoding.transform(input)

      assert_all_close(
        Nx.less_equal(Nx.abs(result), 1.0),
        Nx.tensor([true, true, true, true, true])
      )

      assert_all_close(
        Nx.take(result, Nx.tensor([2])),
        Nx.tensor([0.0])
      )

      # Check symmetry: -x should decode to -decoded(x)
      positive_values = Nx.take(result, Nx.tensor([3, 4]))
      negative_values = Nx.take(result, Nx.tensor([1, 0]))

      assert_all_close(positive_values, Nx.negate(Nx.reverse(negative_values)))
    end

    test "decodes signal with custom quantization channels" do
      input = Nx.tensor([0.1, -0.1])
      result_256 = MuLawDecoding.transform(input)
      result_128 = MuLawDecoding.transform(input, quantization_channels: 128)

      assert Nx.to_flat_list(result_256) != Nx.to_flat_list(result_128)
    end

    test "encoding followed by decoding approximately recovers the original signal" do
      input = Nx.tensor([-0.9, -0.5, -0.1, 0.0, 0.1, 0.5, 0.9])

      encoded = MuLawEncoding.transform(input)
      decoded = MuLawDecoding.transform(encoded)

      # The reconstruction won't be perfect due to compression,
      # but should be reasonably close
      assert_all_close(input, decoded, 1.0e-5, 0.1)
    end

    test "clips input to [-1, 1] range" do
      input = Nx.tensor([-1.5, 1.5])
      result = MuLawDecoding.transform(input)

      assert_all_close(
        Nx.less_equal(Nx.abs(result), 1.0),
        Nx.tensor([true, true])
      )
    end
  end
end
