defmodule NavBuddy2.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/SangRJ/nav_buddy2"

  def project do
    [
      app: :nav_buddy2,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "NavBuddy2",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, ">= 0.20.0"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Permission-aware, multi-layout navigation engine for Phoenix LiveView.
    Supports sidebar, horizontal, mobile drawer, and command palette layouts
    with daisyUI theming and Alpine.js animations.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib assets .formatter.exs mix.exs README.md LICENSE),
      maintainers: ["Sang Rogers"]
    ]
  end

  defp docs do
    [
      main: "NavBuddy2",
      extras: ["README.md"]
    ]
  end
end
