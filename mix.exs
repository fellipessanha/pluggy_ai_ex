defmodule PluggyAiEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :pluggy_ai,
      version: "0.1.0",
      elixir: "~> 1.19",
      name: "PluggyAI",
      description: "Elixir client library for the Pluggy API",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:kino, "~> 0.14", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:plug, "~> 1.16"},
      # dev/test
      {:bandit, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{}
    ]
  end
end
