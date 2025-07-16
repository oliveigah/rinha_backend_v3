defmodule RinhaBackendV3.MixProject do
  use Mix.Project

  def project do
    [
      app: :rinha_backend_v3,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RinhaBackendV3.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.7"},
      {:plug, "~> 1.18"},
      {:finch, "~> 0.20.0"},
      {:uuid_v7, "~> 0.6.0"}
    ]
  end
end
