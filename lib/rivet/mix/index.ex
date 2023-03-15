defmodule Rivet.Mix do
  @moduledoc """
  Common calls across mix tasks
  """

  # @switch_info [
  #   model: [default: true],
  #   lib: [default: true],
  #   migration: [default: true],
  #   test: [default: true],
  #   loader: [default: false],
  #   seeds: [default: false],
  #   graphql: [default: false],
  #   resolver: [default: false],
  #   rest: [default: false],
  #   cache: [default: false]
  # ]
  #
  # @defaults Enum.reduce(@switch_info, %{}, fn {k, opts}, acc ->
  #             if Keyword.has_key?(opts, :default) do
  #               Map.put(acc, k, opts[:default])
  #             else
  #               acc
  #             end
  #           end)
  #           |> Map.to_list()

  @switches [
    lib_dir: [:string, :keep],
    models_dir: [:string, :keep],
    test_dir: [:string, :keep],
    app_base: [:string, :keep],
    #      order: [:integer, :keep],
    model: :boolean
    #      lib: :boolean,
    #      migration: :boolean,
    #      loader: :boolean,
    #      seeds: :boolean,
    #      graphql: :boolean,
    #      resolver: :boolean,
    #      rest: :boolean,
    #      cache: :boolean,
    #      test: :boolean
  ]

  # @aliases [
  #   m: :model,
  #   b: :lib,
  #   l: :loader,
  #   s: :seeds,
  #   g: :graphql,
  #   c: :cache,
  #   t: :test
  # ]

  def parse_options(args, switches, aliases \\ []),
    do: OptionParser.parse(args, strict: @switches ++ switches, aliases: aliases)

  def task_cmd(module) do
    case to_string(module) do
      "Elixir.Mix.Tasks." <> rest -> String.downcase(rest) |> String.replace(".", " ")
    end
  end
end
