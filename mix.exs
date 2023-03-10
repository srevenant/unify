defmodule Rivet.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet,
      version: "1.0.2",
      elixir: "~> 1.13",
      description: "Elixir data model framework library",
      source_url: "https://github.com/srevenant/rivet",
      docs: [main: "Rivet"],
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
        ## insert default options for adding models
        # migrations: []
        # version_strategy: :date # :increment ??
        # app_base: Some.Project.Name, # defaults to modulename form of :app
        # migration_dir: "",
        # lib_dir: "",
        # test_dir: ""
      ]
    ]
  end

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
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      # keystrokes of life
      c: ["compile"]
    ]
  end

  defp deps do
    [
      {:rivet_utils, "~> 1.0.3", git: "git@github.com:srevenant/rivet-utils", branch: "master"},
      {:ecto_sql, "~> 3.9"},
      {:ecto_enum, "~> 1.0"},
      {:transmogrify, "~> 1.1"},
      {:yaml_elixir, "~> 2.8.0"},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      {:postgrex, "~> 0.13", only: [:test]},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/srevenant/rivet"},
      source_url: "https://github.com/srevenant/rivet"
    ]
  end
end
