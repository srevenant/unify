defmodule Rivet.Test.MigrationInclude do
  use Rivet.Case

  test "migration include" do
    on_exit(fn -> File.rm_rf!("priv/rivet/migrations/pinky") end)
    :ok = File.mkdir_p("priv/rivet/migrations/pinky")

    :ok =
      File.write(
        "priv/rivet/migrations/pinky/index.exs",
        inspect([
          [base: true, version: 100, module: Pinky.Brain],
          [base: false, version: 20, module: Pinky.Splat],
          [base: false, version: 3000, module: Pinky.Narf],
          [base: true, version: 0, module: Pinky.Base]
        ])
      )

    opts = [lib_dir: "", models_dir: ""]

    cfg = [app: :rivet]
    Application.put_env(:rivet, :rivet, cfg)

    assert {:ok, rivet_cfg} = Rivet.Config.build(opts, cfg)

    assert {:ok, model_cfg} =
             %{prefix: 200, include: "pinky"}
             |> Rivet.Migration.Load.prepare_model_config(rivet_cfg)

    state = %{idx: %{}, mods: %{}}

    narf_path = Application.app_dir(:rivet, "priv/rivet/migrations/pinky/narf.exs")

    assert {:ok,
            %{
              idx: %{
                20_000_000_000_000_000 => %Rivet.Migration{
                  base: true,
                  index: 20_000_000_000_000_000,
                  module: Pinky.Base,
                  parent: Pinky,
                  prefix: 200,
                  version: 0
                },
                20_000_000_000_000_020 => %Rivet.Migration{
                  base: false,
                  index: 20_000_000_000_000_020,
                  module: Pinky.Splat,
                  parent: Pinky,
                  prefix: 200,
                  version: 20
                },
                20_000_000_000_000_100 => %Rivet.Migration{
                  base: true,
                  index: 20_000_000_000_000_100,
                  module: Pinky.Brain,
                  parent: Pinky,
                  prefix: 200,
                  version: 100
                },
                20_000_000_000_003_000 => %Rivet.Migration{
                  base: false,
                  index: 20_000_000_000_003_000,
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
               "index.exs",
               true
             )
  end
end
