defmodule Ostatus.Mixfile do
  use Mix.Project

  def project do
    [app: :chen_ex,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :ewebmachine, :cowboy, :sweet_xml, :xml_builder, :poison, :riak],
     mod: {ChenEx.App, []} ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:ewebmachine, "~> 2.1"},
      {:cowboy, "~> 1.1"},
      {:sweet_xml, "~> 0.6.5"},
      {:xml_builder, "~> 0.0.9"},
      {:riak, "~> 1.1"}
    ]
  end
end
