defmodule NxAudio.Transforms.MuLawEncodingTest do
  use Nx.Case, async: false

  alias NxAudio.Transforms.MuLawEncoding

  describe "transform/2" do
    test "encodes signal with default quantization channels" do
      input = Nx.tensor([-1.0, -0.5, 0.0, 0.5, 1.0])
      result = MuLawEncoding.transform(input)

      assert_all_close(
        Nx.less_equal(Nx.abs(result), 1.0),
        Nx.tensor([true, true, true, true, true])
      )

      assert_all_close(
        Nx.take(result, Nx.tensor([2])),
        Nx.tensor([0.0])
      )

      # Check symmetry: -x should encode to -encoded(x)
      positive_values = Nx.take(result, Nx.tensor([3, 4]))
      negative_values = Nx.take(result, Nx.tensor([1, 0]))

      assert_all_close(positive_values, Nx.negate(Nx.reverse(negative_values)))
    end

    test "encodes signal with custom quantization channels" do
      input = Nx.tensor([0.1, -0.1])
      result_256 = MuLawEncoding.transform(input)
      result_128 = MuLawEncoding.transform(input, quantization_channels: 128)

      assert Nx.to_flat_list(result_256) != Nx.to_flat_list(result_128)
    end

    test "clips input to [-1, 1] range" do
      input = Nx.tensor([-1.5, 1.5])
      result = MuLawEncoding.transform(input)

      assert_all_close(
        Nx.less_equal(Nx.abs(result), 1.0),
        Nx.tensor([true, true])
      )
    end
  end
end
