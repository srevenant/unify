defmodule Rivet.Test.MigrationExternal do
  use Rivet.Case

  test "migration external" do
    [_ | _] = File.cp_r!("priv/rivet_test_lib", "deps/rivet_test_lib")
    tmp = temp_dir()
    root = "#{tmp}/pinky"
    :ok = File.mkdir_p("#{root}/migrations")

    :ok =
      File.write(
        "#{root}/migrations/.index.exs",
        inspect([
          [base: true, version: 0, module: Base]
        ])
      )

    :ok =
      File.write(
        "#{root}/migrations/base.exs",
        """
        defmodule Pinky.Base do
          use Ecto.Migration

          def change do
            create table(:base, primary_key: false) do
              add(:id, :uuid, primary_key: true)
            end
          end
        end
        """
      )

    :ok =
      File.write(
        "#{tmp}/.migrations.exs",
        inspect([
          [
            include: Pinky,
            prefix: 400
          ],
          [
            external: "deps/rivet_test_lib",
            migrations: [
              [include: RivetTestLib.Yoink.Migrations, prefix: 300]
            ]
          ]
        ])
      )

    on_exit(fn ->
      :ok
      # File.rm_rf!(tmp)
      # File.rm_rf!("deps/rivet_test_lib")
    end)

    opts = [base_dir: tmp, lib_dir: ".", models_dir: ""]
    cfg = Mix.Project.config()

    assert {:ok,
            [
              {30_000_000_000_000_000, RivetTestLib.Yoink.Migrations.Base},
              {40_000_000_000_000_000, Pinky.Base}
            ]} = Rivet.Migration.Load.prepare_project_migrations(opts, cfg)
  end
end
