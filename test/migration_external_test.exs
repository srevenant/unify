defmodule Rivet.Test.MigrationExternal do
  use Rivet.Case

  test "migration external" do
    Code.prepend_path("test/support/pinky/ebin")
    Code.prepend_path("test/support/rivet_test_lib/ebin")
    Application.ensure_loaded(:rivet_test_lib)
    Application.ensure_loaded(:pinky)

    opts = [base_dir: ".", lib_dir: ".", models_dir: ""]

    assert {:ok, migs} = Rivet.Migration.Load.prepare_project_migrations(opts, :pinky)

    assert {:ok,
            [
              {30_000_000_000_000_000, RivetTestLib.Yoink.Migrations.Base},
              {40_000_000_000_000_000, Pinky.Base},
              {40_000_000_000_000_020, Pinky.Splat},
              {40_000_000_000_000_100, Pinky.Brain},
              {40_000_000_000_003_000, Pinky.Narf}
            ]} = Rivet.Migration.Load.to_ecto_migrations(migs)
  end
end
