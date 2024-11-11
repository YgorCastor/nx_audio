defmodule NxAudio.MixProject do
  use Mix.Project

  def project do
    [
      app: :nx_audio,
      version: "0.1.0",
      elixir: "~> 1.17",
      aliases: aliases(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_core_path: "_plts/core"
      ],
      source_url: "https://github.com/YgorCastor/nx_audio.git",
      homepage_url: "https://github.com/YgorCastor/nx_audio.git",
      docs: [
        main: "readme",
        extras: [
          "CHANGELOG.md": [title: "Changelog"],
          "README.md": [title: "Introduction"],
          LICENSE: [title: "License"]
        ],
        groups_for_modules: [
          Common: &(&1[:section] == :commons),
          IO: &(&1[:section] == :io)
        ],
        nest_modules_by_prefix: [
          NxAudio.Commons,
          NxAudio.IO
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:briefly, "~> 0.5"},
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.21", only: [:dev], runtime: false},
      {:enum_type, "~> 1.1"},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:ffmpex, "~> 0.11"},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:nimble_options, "~> 1.1"},
      {:nx, "~> 0.9"},
      {:splode, "~> 0.2"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["test --exclude integration"],
      "test.integration": ["test --only integration"]
    ]
  end

  def cli do
    [preferred_envs: ["test.integration": :test]]
  end

  defp description() do
    "NxAudio is a analogous implementation for the python torchaudio library for NX"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/YgorCastor/nx_audio.git"},
      sponsor: "ycastor.eth"
    ]
  end
end
