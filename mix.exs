defmodule Rivet.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet,
      version: "1.0.0",
      elixir: "~> 1.13",
      description: "Elixir data model framework library",
      source_url: "https://github.com/srevenant/rivet",
      docs: [main: "Rivet.Utils"],
      package: package(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      rivet: [
        migration_prefix: "00"
        # app_base: Some.Project.Name, # defaults to modulename form of :app
        # migration_dir: "",
        # lib_dir: "",
        # test_dir: ""
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Rivet.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "core.seeds"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      # keystrokes of life
      c: ["compile"]
    ]
  end

  defp deps do
    [
      {:rivet_utils, "~> 1.0.0", git: "git@github.com:srevenant/rivet-utils", branch: "master"},
      {:ecto_enum, "~> 1.0"},
      {:ecto_sql, "~> 3.7"},
      {:transmogrify, "~> 1.0.0"},
      {:yaml_elixir, "~> 2.8.0"},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      {:postgrex, "~> 0.13", only: [:test]},
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["AGPL-3.0-or-later"],
      links: %{"GitHub" => "https://github.com/srevenant/rivet"},
      source_url: "https://github.com/srevenant/rivet"
    ]
  end
end
