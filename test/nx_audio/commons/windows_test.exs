defmodule NxAudio.Commons.WindowsTest do
  use Nx.Case, async: true

  alias NxAudio.Commons.Windows

  describe "haan" do
    test "creates periodic hann window" do
      window = Windows.haan(window_length: 4, periodic: true)
      expected = Nx.tensor([0.0, 0.5, 0.5, 0.0])
      assert_all_close(window, expected)
    end

    test "creates symmetric (non-periodic) hann window" do
      window = Windows.haan(window_length: 4, periodic: false)
      expected = Nx.tensor([0.0, 0.5, 1.0, 0.5])
      assert_all_close(window, expected)
    end

    test "creates window of length 1" do
      window = Windows.haan(window_length: 1)
      expected = Nx.tensor([1.0])
      assert_all_close(window, expected)
    end

    test "handles odd length windows" do
      window = Windows.haan(window_length: 5, periodic: true)
      # Should be symmetric around the center
      expected = Nx.tensor([0.0, 0.5, 0.8535533905932737, 0.5, 0.0])
      assert_all_close(window, expected)
    end
  end
end
