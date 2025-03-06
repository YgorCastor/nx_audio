defmodule NxAudio.Commons.Windows do
  @moduledoc """
  NX Implementation of common window functions.
  """
  @moduledoc section: :common_utils
  import Nx.Defn

  # TODO: Replace this with Nx.Signal once the Kaiser window is published

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

  # INFO: I implemented this on NxSignal, but it is not published yet, remove once its published

  @doc """
  Creates a Kaiser window of size `window_length`.

  The Kaiser window is a taper formed by using a Bessel function.

  ## Options

    * `:is_periodic` - If `true`, produces a periodic window,
       otherwise produces a symmetric window. Defaults to `true`
    * `:type` - the output type for the window. Defaults to `{:f, 32}`
    * `:beta` - Shape parameter for the window. As beta increases, the window becomes more focused in frequency domain. Defaults to 12.0.
    * `:eps` - Epsilon value to avoid division by zero. Defaults to 1.0e-7.
    * `:axis_name` - the axis name. Defaults to `nil`
  """
  deftransform kaiser(n, opts \\ []) when is_integer(n) do
    opts =
      Keyword.validate!(opts, [:name, eps: 1.0e-7, beta: 12.0, is_periodic: true, type: {:f, 32}])

    kaiser_n(Keyword.put(opts, :n, n))
  end

  defnp kaiser_n(opts) do
    n = opts[:n]
    name = opts[:name]
    type = opts[:type]
    beta = opts[:beta]
    eps = opts[:eps]
    is_periodic = opts[:is_periodic]

    window_length = if is_periodic, do: n + 1, else: n

    ratio = Nx.linspace(-1, 1, n: window_length, endpoint: true, type: type, name: name)
    sqrt_arg = Nx.max(1 - ratio ** 2, eps)
    r = beta * Nx.sqrt(sqrt_arg)

    window = kaiser_bessel_i0(r) / kaiser_bessel_i0(beta)

    if is_periodic do
      Nx.slice(window, [0], [n])
    else
      window
    end
  end

  defnp kaiser_bessel_i0(x) do
    abs_x = Nx.abs(x)

    small_x_result =
      1 +
        abs_x ** 2 / 4 +
        abs_x ** 4 / 64 +
        abs_x ** 6 / 2304 +
        abs_x ** 8 / 147_456

    large_x_result =
      Nx.exp(abs_x) / Nx.sqrt(2 * Nx.Constants.pi() * abs_x) *
        (1 + 1 / (8 * abs_x) + 9 / (128 * Nx.pow(abs_x, 2)))

    Nx.select(abs_x < 3.75, small_x_result, large_x_result)
  end
end
