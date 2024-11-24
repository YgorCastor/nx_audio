defmodule NxAudio.Transforms.AmplitudeToDbTest do
  use ExUnit.Case, async: true
  alias NxAudio.Transforms.AmplitudeToDb

  describe "transform/2" do
    test "converts power spectrogram to db" do
      input = Nx.tensor([1.0, 10.0, 100.0])
      expected = Nx.tensor([0.0, 10.0, 20.0])
      result = AmplitudeToDb.transform(input, scale: :power)

      assert_all_close(result, expected)
    end

    test "converts magnitude spectrogram to db" do
      input = Nx.tensor([1.0, 10.0, 100.0])
      expected = Nx.tensor([0.0, 20.0, 40.0])
      result = AmplitudeToDb.transform(input, scale: :magnitude)

      assert_all_close(result, expected)
    end

    test "clamps values according to top_db" do
      input = Nx.tensor([0.1, 1.0, 10.0, 100.0])
      result = AmplitudeToDb.transform(input, scale: :power, top_db: 30.0)

      # Maximum value should be 20.0 (from log10(100) * 10)
      # Minimum value should be -10.0 (20.0 - 30.0)
      max_val = Nx.reduce_max(result)
      min_val = Nx.reduce_min(result)

      assert_all_close(max_val, Nx.tensor(20.0))
      assert_all_close(min_val, Nx.tensor(-10.0))
    end

    test "handles very small values" do
      input = Nx.tensor([1.0e-11])
      result = AmplitudeToDb.transform(input, scale: :power)

      # Should use the minimum value of 1.0e-10
      expected = Nx.tensor([-100.0])
      assert_all_close(result, expected)
    end

    test "raises error for invalid scale option" do
      assert_raise ArgumentError, ~r/Invalid :scale option/, fn ->
        AmplitudeToDb.transform(Nx.tensor([1.0]), scale: :invalid)
      end
    end
  end

  # Helper function to assert that tensors are approximately equal
  defp assert_all_close(actual, expected, rtol \\ 1.0e-5, atol \\ 1.0e-8) do
    diff = Nx.abs(Nx.subtract(actual, expected))
    tol = Nx.add(Nx.multiply(rtol, Nx.abs(expected)), atol)

    assert Nx.all(Nx.less_equal(diff, tol))
  end
end
