defmodule NxAudio.Fixtures.AudioTensors do
  @moduledoc false

  @doc false
  def new_pcm_with_sr(sample_rate) do
    time = Nx.tensor(Enum.map(0..(sample_rate - 1), fn x -> x / sample_rate end))
    frequency = 440.0

    time
    |> Nx.multiply(2 * :math.pi() * frequency)
    |> Nx.sin()
    |> Nx.multiply(32_767.0)
    |> Nx.new_axis(-1)
    |> Nx.transpose()
  end
end
