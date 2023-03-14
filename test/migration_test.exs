defmodule Rivet.Test.Migration do
  use Rivet.Case, async: true

  @test_root "test/temp/pinky"

  setup do
    on_exit(fn -> File.rm_rf!(@test_root) end)
  end

  test "migration things" do
    File.write(
      @test_file,
      inspect([
        [base: true, version: 100, module: Brain],
        [base: true, version: 20, module: Splat],
        [base: true, version: 3000, module: Narf],
        [base: true, version: 0, module: Base]
      ])
    )

    opts = [lib_dir: ".", models_dir: ""]

    assert {:ok, cfg} = Rivet.Config.build(opts, Mix.Project.config())

    assert {:ok, cfg, path} =
             %{prefix: 200, include: Pinky}
             |> Rivet.Migration.Load.prepare_model_config(cfg)

    state = %{idx: %{}, mods: %{}}

    {:ok, state}
    |> Rivet.Migration.Load.merge_model_migrations(cfg, path, @test_file, true)
    |> IO.inspect()
  end
end
