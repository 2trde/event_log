defmodule EventLog.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_log,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:meck, "~> 0.8"},
      {:poison, ">= 3.0.0"},
      {:timex, "~> 3.0"},
      {:rollbax, "~> 0.11.0"}
    ]
  end
end
