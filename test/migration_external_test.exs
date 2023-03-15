defmodule Rivet.Test.MigrationExternal do
  use Rivet.Case, async: true

  test "migration external" do
    [_|_] = File.cp_r!("priv/rivet_test_lib", "deps/rivet_test_lib")
    tmp = temp_dir()
    :ok = File.mkdir_p!(tmp)
    :ok =
      File.write(
        "#{tmp}/.migrations.exs",
        inspect([
            external: RivetTestLib,
            migrations: [
              [include: RivetTestLib.Yoink.Migrations, prefix: 300]
            ]
        ])
      )

    on_exit(fn ->
      File.rm_rf!(tmp)
      File.rm_rf!("deps/rivet_test_lib")
    end)

    opts = [lib_dir: tmp, models_dir: ""]
    assert {:ok, rivet_cfg} = Rivet.Config.build(opts, Mix.Project.config())
    assert {:ok,
            %{
              idx: :red
            }} =
              Rivet.Migration.Load.prepare_project_migrations([], rivet_cfg)
  end
end
