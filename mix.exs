defmodule ArcAzure.MixProject do
  use Mix.Project

  def project do
    [
      app: :arc_azure,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  defp description do
    """
    Provides Microsoft Azure Storage for Arc.
    """
  end

  defp package do
    [maintainers: ["Phil"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/phil-a/arc_azure"},
     files: ~w(mix.exs README.md lib)]
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
      {:arc, "~> 0.8"},
      {:ex_azure, "~> 0.1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
