defmodule MembraneNodeProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_node_proxy,
      deps: deps(),
      dialyzer: dialyzer(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application do
    [
      mod: {Membrane.NodeProxy, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:membrane_core, "~> 0.7.0"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end
