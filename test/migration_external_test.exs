defmodule Rivet.Test.MigrationExternal do
  use Rivet.Case

  test "migration external" do
    Code.prepend_path("test/support/rivet_test_lib/ebin")
    Application.ensure_loaded(:rivet_test_lib)
    :ok = File.mkdir_p("priv/rivet/pinky")

    :ok =
      File.write(
        "priv/rivet/pinky/index.exs",
        inspect([
          [base: true, version: 0, module: Pinky.Base]
        ])
      )

    :ok =
      File.write(
        "priv/rivet/pinky/base.exs",
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
        "priv/rivet/migrations.exs",
        inspect([
          [
            include: "pinky",
            prefix: 400
          ],
          [
            external: :rivet_test_lib,
            migrations: [
              [include: "yoink", prefix: 300]
            ]
          ]
        ])
      )

    on_exit(fn ->
      File.rm_rf!("priv/rivet")
    end)

    opts = [base_dir: ".", lib_dir: ".", models_dir: ""]
    cfg = [app: :rivet]
    Application.put_env(:rivet, :rivet, cfg)

    assert {:ok, migs} = Rivet.Migration.Load.prepare_project_migrations(opts, :rivet)

    assert {:ok,
            [
              {30_000_000_000_000_000, RivetTestLib.Yoink.Migrations.Base},
              {40_000_000_000_000_000, Pinky.Base}
            ]} = Rivet.Migration.Load.to_ecto_migrations(migs)
  end
end
