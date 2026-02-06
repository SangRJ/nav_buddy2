defmodule NavBuddy2.MixProject do
  use Mix.Project

  def project do
    [
      app: :nav_buddy2,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.20"},
      {:heroicons, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end

  defp description do
    "Permission-aware, multi-layout navigation system for Phoenix LiveView with daisyUI support."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/SangRJ/nav_buddy2"
      }
    ]
  end
end
