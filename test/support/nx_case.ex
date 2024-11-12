defmodule Nx.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Nx.Defn
      import Nx.Case
    end
  end

  setup config do
    Nx.Defn.default_options(compiler: test_compiler())
    Nx.default_backend(test_backend())
    Process.register(self(), config.test)
    :ok
  end

  def test_compiler do
    use_exla? = System.get_env("USE_EXLA")
    if use_exla?, do: EXLA, else: Nx.Defn.Evaluator
  end

  def test_backend do
    cond do
      System.get_env("USE_TORCHX") -> Torchx.Backend
      System.get_env("USE_EXLA") -> EXLA.Backend
      true -> Nx.BinaryBackend
    end
  end

  def assert_all_close(actual, expected, rtol \\ 1.0e-5, atol \\ 1.0e-8) do
    diff = Nx.subtract(actual, expected)
    tol = Nx.add(atol, Nx.multiply(rtol, Nx.abs(expected)))
    assert Nx.all(Nx.less_equal(Nx.abs(diff), tol))
  end
end
