defmodule Rivet.Test.Migration do
  use Rivet.Case, async: true

  @lib_dir "tmp"
  @test_root "#{@lib_dir}/pinky"

  setup do
    on_exit(fn -> File.rm_rf!(@test_root) end)
  end

  test "migration things" do
    :ok = File.mkdir_p("#{@test_root}/migrations")

    :ok =
      File.write(
        "#{@test_root}/migrations/.index.exs",
        inspect([
          [base: true, version: 100, module: Brain],
          [base: true, version: 20, module: Splat],
          [base: true, version: 3000, module: Narf],
          [base: true, version: 0, module: Base]
        ])
      )

    opts = [lib_dir: @lib_dir, models_dir: ""]

    assert {:ok, rivet_cfg} = Rivet.Config.build(opts, Mix.Project.config())

    assert {:ok, model_cfg} =
             %{prefix: 200, include: Pinky}
             |> Rivet.Migration.Load.prepare_model_config(rivet_cfg)

    state = %{idx: %{}, mods: %{}}

    assert {:ok,
            %{
              idx: %{
                20_000_000_000_000_000 => %{
                  base: true,
                  index: 20_000_000_000_000_000,
                  model: "Pinky",
                  module: Pinky.Base,
                  parent: Pinky,
                  path: "#{@lib_dir}/pinky/migrations/base.exs",
                  prefix: 200,
                  version: 0
                },
                20_000_000_000_000_020 => %{
                  base: true,
                  index: 20_000_000_000_000_020,
                  model: "Pinky",
                  module: Pinky.Splat,
                  parent: Pinky,
                  path: "#{@lib_dir}/pinky/migrations/splat.exs",
                  prefix: 200,
                  version: 20
                },
                20_000_000_000_000_100 => %{
                  base: true,
                  index: 20_000_000_000_000_100,
                  model: "Pinky",
                  module: Pinky.Brain,
                  parent: Pinky,
                  path: "#{@lib_dir}/pinky/migrations/brain.exs",
                  prefix: 200,
                  version: 100
                },
                20_000_000_000_003_000 => %{
                  base: true,
                  index: 20_000_000_000_003_000,
                  model: "Pinky",
                  module: Pinky.Narf,
                  parent: Pinky,
                  path: "#{@lib_dir}/pinky/migrations/narf.exs",
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
