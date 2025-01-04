defmodule NxAudio.Commons.Windows do
  @moduledoc """
  NX Implementation of common window functions.
  """
  @moduledoc section: :common_utils
  import Nx.Defn

  @pi 3.141592653589793
  @eps 2.220446049250313e-16

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

  @doc """
  Creates a Kaiser window of size `window_length`.

  The Kaiser window is a taper formed by using a Bessel function.

  Args:
    window_length: Length of the window. Must be positive integer.
    beta: Shape parameter for the window. As beta increases, the window becomes more focused in frequency domain.
          When beta = 0, the window becomes rectangular. Defaults to 12.0.
    periodic: If true, returns a periodic window for use with FFT. Defaults to true.

  Returns:
    A 1-D tensor of size (window_length,) containing the window

  ## Examples
      iex> Windows.kaiser(window_length: 4, beta: 12.0)
      #Nx.Tensor<
        f32[4]
        [0.0, 0.5, 0.5, 0.0]
      >
  """
  defn kaiser(opts) do
    opts = keyword!(opts, window_length: 1, beta: 12.0, periodic: true)
    window_length = opts[:window_length]
    beta = opts[:beta]
    periodic = opts[:periodic]

    computation_length = if periodic, do: window_length + 1, else: window_length

    alpha = (computation_length - 1) / 2.0

    n = Nx.iota({computation_length}, type: :f32)
    ratio = (n - alpha) / alpha
    r = beta * Nx.sqrt(1 - Nx.pow(ratio, 2) + @eps)

    # Calculate window values
    window = _i0(r) / _i0(beta)

    # If periodic, remove the last point
    if periodic == 1 do
      Nx.slice(window, [0], [window_length])
    else
      window
    end
  end

  defnp _i0(x) do
    terms = 50

    n = Nx.iota({terms}, type: :f32)
    seq = Nx.add(n, 1)
    facts = Nx.cumulative_product(seq)

    half_x = Nx.divide(x, 2)
    half_x = Nx.reshape(half_x, {Nx.size(half_x), 1})

    powers = Nx.pow(half_x, n)
    terms = Nx.divide(powers, facts)
    squared = Nx.multiply(terms, terms)

    Nx.sum(squared, axes: [1])
  end
end
