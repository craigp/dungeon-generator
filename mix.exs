defmodule Dungeon.Mixfile do

  use Mix.Project

  def project do
    [app: :dungeon_generator,
     version: "0.0.1",
     escript: [main_module: DungeonGenerator],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [
       remote_defaults: :unknown,
       ignore_warnings: "dialyzer.ignore-warnings"
     ],
     deps: deps()]
  end

  defp deps do
    [
      {:bunt, "~> 0.2"},
      # {:dialyxir, "~> 0.3", only: :dev}
    ]
  end

end
