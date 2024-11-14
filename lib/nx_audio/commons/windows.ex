defmodule NxAudio.Commons.Windows do
  @moduledoc """
  NX Implementation of common window functions.
  """
  import Nx.Defn

  @pi 3.141592653589793

  @doc """
  Creates a Hann window of size `window_length`.  

  Args:
    window_length: Length of the window. Must be positive integer.  
    periodic: If true, returns a periodic window for use with FFT. Defaults to true.  

  Returns:
    A 1-D tensor of size (window_length,) containing the window  

  ## Examples
      iex> Hann.create(window_length: 4)
      #Nx.Tensor
        f32[4]
        [0.0, 0.5, 0.5, 0.0]
      >
  """
  defn haan(opts) do
    opts = keyword!(opts, window_length: 1, periodic: true)
    window_length = opts[:window_length]
    periodic = opts[:periodic]

    # For periodic windows, we compute N+1 points and discard the last one
    computation_length = if periodic, do: window_length + 1, else: window_length

    n = Nx.iota({computation_length})
    window = 0.5 - 0.5 * Nx.cos(2 * @pi * n / (computation_length - 1))

    # If periodic, remove the last point
    if periodic == 1 do
      Nx.slice(window, [0], [window_length])
    else
      window
    end
  end
end
