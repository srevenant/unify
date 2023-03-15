defmodule Rivet.Test.MigrationInclude do
  use Rivet.Case

  test "migration include" do
    tmp = temp_dir()
    :ok = File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)
    root = "#{tmp}/pinky"
    :ok = File.mkdir_p("#{root}/migrations")

    :ok =
      File.write(
        "#{root}/migrations/.index.exs",
        inspect([
          [base: true, version: 100, module: Brain],
          [base: false, version: 20, module: Splat],
          [base: false, version: 3000, module: Narf],
          [base: true, version: 0, module: Base]
        ])
      )

    opts = [lib_dir: tmp, models_dir: ""]

    assert {:ok, rivet_cfg} = Rivet.Config.build(opts, Mix.Project.config())

    assert {:ok, model_cfg} =
             %{prefix: 200, include: Pinky}
             |> Rivet.Migration.Load.prepare_model_config(rivet_cfg)

    state = %{idx: %{}, mods: %{}}

    narf_path = "#{tmp}/pinky/migrations/narf.exs"

    assert {:ok,
            %{
              idx: %{
                20_000_000_000_000_000 => %Rivet.Migration{
                  base: true,
                  index: 20_000_000_000_000_000,
                  model: "Pinky",
                  module: Pinky.Base,
                  parent: Pinky,
                  prefix: 200,
                  version: 0
                },
                20_000_000_000_000_020 => %Rivet.Migration{
                  base: false,
                  index: 20_000_000_000_000_020,
                  model: "Pinky",
                  module: Pinky.Splat,
                  parent: Pinky,
                  prefix: 200,
                  version: 20
                },
                20_000_000_000_000_100 => %Rivet.Migration{
                  base: true,
                  index: 20_000_000_000_000_100,
                  model: "Pinky",
                  module: Pinky.Brain,
                  parent: Pinky,
                  prefix: 200,
                  version: 100
                },
                20_000_000_000_003_000 => %Rivet.Migration{
                  base: false,
                  index: 20_000_000_000_003_000,
                  model: "Pinky",
                  module: Pinky.Narf,
                  parent: Pinky,
                  path: ^narf_path,
                  prefix: 200,
                  version: 3000
                }
              },
              mods: %{
                Pinky.Base => [],
                Pinky.Brain => [],
                Pinky.Narf => [],
                Pinky.Splat => []
              }
            }} =
             Rivet.Migration.Load.merge_model_migrations(
               {:ok, state},
               model_cfg,
               ".index.exs",
               true
             )
  end
end
